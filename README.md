# SanoPublicationDB

for taking track of Sano's researchers publications and providing statistics of them

## API Documentation

The application provides a RESTful API for accessing publication statistics. All API endpoints return JSON responses.

Unless stated otherwise, publication-based statistics exclude publications with status `submitted`.

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
| `/publications_by_research_groups_count` | Count of primary publications by research group | Object with research group keys and count values |
| `/publications_by_year` | Count of publications by publication year | Object with year keys and count values |

#### Journal Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/journals_count` | Total number of journal issues with at least one publication | Integer |
| `/journal_with_most_publications` | Journal issue with the highest number of publications | JournalIssue object with `publication_count` |
| `/average_impact_factor` | Average impact factor across journal issues linked to publications | String (formatted to 2 decimal places) or Integer `0` |

#### Conference Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/conferences_count` | Total number of conferences with at least one publication | Integer |
| `/conference_with_most_publications` | Conference with the highest number of publications | Conference object with `publication_count` |

#### Open Access Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/open_access_publications_count` | Total number of open access publications | Integer |
| `/open_access_publications_percentage` | Percentage of publications that are open access | String (formatted to 2 decimal places, 0-100) |
| `/green_open_access_publications_count` | Count of green open access publications | Integer |
| `/gold_open_access_publications_count` | Count of gold open access publications | Integer |

#### Other Statistics

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `/average_subsidy_points` | Average subsidy points across publications | String (formatted to 2 decimal places) or Integer `0` |

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
