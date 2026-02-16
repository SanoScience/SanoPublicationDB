# SanoPublicationDB

for taking track of Sano's researchers publications and providing statistics of them

## API Documentation

The application provides a RESTful API for accessing publication statistics. All API endpoints return JSON responses.

### Base URL

```
{application_url}/api/statistics
```

### Available Endpoints

#### Publication Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/publications_count` | Total number of publications | Integer |
| `/publications_by_category_count` | Count of publications by category | Object with category keys and count values |
| `/publications_by_status_count` | Count of publications by status | Object with status keys and count values |
| `/publications_by_research_groups_count` | Count of publications by research group | Object with research group keys and count values |

#### Journal Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/journals_count` | Total number of journals | Integer |
| `/journal_with_most_publications` | Journal with the highest number of publications | Journal object with publication_count |
| `/average_impact_factor` | Average impact factor across all journals | Float |

#### Conference Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/conferences_count` | Total number of conferences | Integer |
| `/conference_with_most_publications` | Conference with the highest number of publications | Conference object with publication_count |

#### Open Access Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/open_access_publications_count` | Total number of open access publications | Integer |
| `/open_access_publications_percentage` | Percentage of publications that are open access | Float (0-100) |
| `/green_open_access_publications_count` | Count of green open access publications | Integer |
| `/gold_open_access_publications_count` | Count of gold open access publications | Integer |

#### Other Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/average_subsidy_points` | Average subsidy points across publications | String (formatted to 5 decimal places) |

### Example Usage

```javascript
// Example: Fetch the total number of publications
fetch('/api/statistics/publications_count')
  .then(response => response.json())
  .then(count => console.log(`Total publications: ${count}`));

// Example: Get publications by category
fetch('/api/statistics/publications_by_category_count')
  .then(response => response.json())
  .then(data => {
    Object.entries(data).forEach(([category, count]) => {
      console.log(`${category}: ${count} publications`);
    });
  });
```
