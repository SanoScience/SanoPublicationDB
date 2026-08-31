require "test_helper"

class Api::OpenalexSearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user) 
    sign_in @user
  end

  test "returns bad request if DOI is missing" do
    get "/api/openalex/search", params: { doi: "" }
    
    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "DOI parameter is required", json["error"]
  end

  test "maps general publication metadata correctly" do
    mock_response = {
      "id" => "https://openalex.org/W123456",
      "doi" => "https://doi.org/10.1038/test.doi",
      "title" => "Test Article",
      "type" => "article",
      "publication_year" => 2023,
      "publication_date" => "2023-01-01",
      "open_access" => { "is_oa" => true, "oa_status" => "gold" },
      "primary_location" => {
        "source" => {
          "type" => "journal",
          "display_name" => "Test Journal",
          "publisher" => "Test Publisher"
        }
      },
      "biblio" => {
        "volume" => "5",
        "issue" => "2"
      }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1038/test.doi" }
    end

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "Test Article", json["title"]
    assert_equal "journal_article", json["category"]
    assert_equal "printed", json["status"]
    assert_equal "gold", json["open_access"]["status"]
    
    assert_equal "new", json["journal"]["match_type"]
    assert_equal "Test Journal", json["journal"]["title"]
    assert_equal "5", json["journal"]["volume"]
  end

  test "maps existing journal correctly based on title and volume" do
    existing_journal = journal_issues(:jour1)

    mock_response = {
      "id" => "https://openalex.org/W111",
      "type" => "article",
      "primary_location" => {
        "source" => { "type" => "journal", "display_name" => "Example Journal" }
      },
      "biblio" => { "volume" => 1 }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/existing.journal" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    journal = json["journal"]
    assert_not_nil journal
    assert_equal "existing", journal["match_type"]
    assert_equal existing_journal.id, journal["id"]
    assert_equal "Example Journal", journal["title"]
    assert_equal 1, journal["volume"]
  end

  test "maps new journal correctly when not found in DB" do
    mock_response = {
      "id" => "https://openalex.org/W222",
      "type" => "article",
      "primary_location" => {
        "source" => { 
          "type" => "journal", 
          "display_name" => "Brand New Science",
          "publisher" => "Global Press"
        }
      },
      "biblio" => { "volume" => 42, "issue" => "7" }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/new.journal" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    journal = json["journal"]
    assert_not_nil journal
    assert_equal "new", journal["match_type"]
    assert_nil journal["id"]
    assert_equal "Brand New Science", journal["title"]
    assert_equal "Global Press", journal["publisher"]
    assert_equal 42, journal["volume"]
    assert_equal "7", journal["journal_num"]
  end

  test "maps existing conference correctly based on name (using fallback raw_source_name)" do
    existing_conf = conferences(:conf1)

    mock_response = {
      "id" => "https://openalex.org/W333",
      "type" => "conference-paper",
      "primary_location" => {
        "raw_source_name" => "Example Conference" 
      }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/existing.conf" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    conf = json["conference"]
    assert_not_nil conf
    assert_equal "existing", conf["match_type"]
    assert_equal existing_conf.id, conf["id"]
    assert_equal "Example Conference", conf["name"]
  end

  test "maps new conference correctly when not found in DB" do
    mock_response = {
      "id" => "https://openalex.org/W444",
      "type" => "other",
      "primary_location" => {
        "raw_type" => "proceedings-article",
        "source" => { "type" => "conference", "display_name" => "Future Tech 2026" }
      }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/new.conf" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    conf = json["conference"]
    assert_not_nil conf
    assert_equal "new", conf["match_type"]
    assert_nil conf["id"]
    assert_equal "Future Tech 2026", conf["name"]
  end

  test "maps various identifier types correctly" do
    mock_response = {
      "id" => "https://openalex.org/W123456",
      "doi" => "https://doi.org/10.1038/test.doi",
      "type" => "article",
      "primary_location" => {
        "source" => {
          "issn" => ["1234-5678", "8765-4321"]
        }
      },
      "ids" => {
        "openalex" => "https://openalex.org/W123456",
        "doi" => "https://doi.org/10.1038/test.doi",
        "pmid" => "https://pubmed.ncbi.nlm.nih.gov/999999", 
        "isbn" => "https://openalex.org/isbn/978-3",
        "mag" => "12345"
      }
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1038/test.doi" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    identifiers = json["identifiers"]

    assert_includes identifiers, { "category" => "doi", "value" => "doi:10.1038/test.doi" }
    assert_includes identifiers, { "category" => "openalex", "value" => "W123456" }
    assert_includes identifiers, { "category" => "issn", "value" => "1234-5678" }
    assert_includes identifiers, { "category" => "issn", "value" => "8765-4321" }
    assert_includes identifiers, { "category" => "isbn", "value" => "978-3" }
    assert_includes identifiers, { "category" => "other", "value" => "pmid:999999" }
  end

  test "returns nil for status if article is a preprint" do
    mock_response = {
      "id" => "https://openalex.org/W98765",
      "title" => "ArXiv Preprint",
      "type" => "preprint",
      "publication_date" => "2023-05-05",
      "ids" => {}
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/preprint" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_nil json["status"]
  end

  test "maps existing and new authors correctly via OpenalexMatcher" do
    existing_author = authors(:person)

    mock_response = {
      "id" => "https://openalex.org/W123456",
      "type" => "article",
      "authorships" => [
        {
          "author_position" => "first",
          "author" => { "display_name" => "John Doe" }
        },
        {
          "author_position" => "last",
          "author" => { "display_name" => "Jane Smith" }
        }
      ]
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1038/test.authors" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    authors = json["authors"]
    assert_not_nil authors
    assert_equal 2, authors.length

    existing_result = authors.first
    assert_equal "existing", existing_result["match_type"]
    assert_equal existing_author.id, existing_result["id"]
    assert_equal "John Doe", existing_result["display_name"]
    assert_nil existing_result["first_name"]

    new_result = authors.last
    assert_equal "new", new_result["match_type"]
    assert_nil new_result["id"]
    assert_equal "person", new_result["author_type"]
    assert_equal "Jane", new_result["first_name"]
    assert_equal "Smith", new_result["last_name"]
  end

  test "maps existing and new collective authors correctly via OpenalexMatcher" do
    existing_collective = authors(:collective)

    mock_response = {
      "id" => "https://openalex.org/W999999",
      "type" => "article",
      "authorships" => [
        {
          "author_position" => "first",
          "author" => { "display_name" => "Test Team" }
        },
        {
          "author_position" => "last",
          "author" => { "display_name" => "Global Science Consortium" }
        }
      ]
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1038/test.collective" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    authors = json["authors"]
    assert_not_nil authors
    assert_equal 2, authors.length

    existing_result = authors.first
    assert_equal "existing", existing_result["match_type"]
    assert_equal existing_collective.id, existing_result["id"]
    assert_equal "Test Team", existing_result["display_name"]
    assert_nil existing_result["first_name"]

    new_result = authors.last
    assert_equal "new", new_result["match_type"]
    assert_nil new_result["id"]
    
    assert_equal "collective", new_result["author_type"]
    assert_equal "Global Science Consortium", new_result["collective_name"]
    assert_nil new_result["first_name"]
  end

  test "ignores open access if status is not in allowed list" do
    mock_response = {
      "id" => "https://openalex.org/W55555",
      "title" => "Hybrid Article",
      "type" => "article",
      "open_access" => { "is_oa" => true, "oa_status" => "hybrid" },
      "ids" => {}
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/hybrid" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_nil json["open_access"]
  end

  test "handles gracefully incomplete or broken API responses without crashing" do
    mock_response = {
      "title" => "Incomplete Article",
      "type" => "book"
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) { |doi| mock_response }

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/broken" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal "Incomplete Article", json["title"]
    assert_equal "book", json["category"]
    assert_nil json["status"]
    assert_empty json["identifiers"]
  end

  test "returns not found error if API raises NotFoundError" do
    mock_client = Object.new
    mock_client.define_singleton_method(:work_by_doi) do |doi|
      raise Integrations::Openalex::Client::NotFoundError, "Work not found"
    end

    stub_openalex_client(mock_client) do
      get "/api/openalex/search", params: { doi: "10.1234/missing" }
    end

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Work not found", json["error"]
  end

  private

  def stub_openalex_client(mock_instance)
    Integrations::Openalex::Client.define_singleton_method(:new) { mock_instance }

    yield
  ensure
    Integrations::Openalex::Client.singleton_class.remove_method(:new)
  end
end
