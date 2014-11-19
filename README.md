Quickly find your GitHub repositories from [Alfred](http://www.alfredapp.com/).

# Download from Packal

<http://www.packal.org/workflow/github-repos>


# Usage

This workflow searches among your public and private repositories (including organizations you belong to) and opens them on GitHub.

### Identify yourself

As one-time setup, you need to provide a GitHub API access token to authenticate:

[Create a new personal access token](https://github.com/settings/tokens/new). You can enter any description; scope `repo` (read private repositories) is sufficient.

![New personal access token](http://cloud.edgar.sh/2z7pq.png)

Then **copy the token** (as it will be visible only that time!), and authenticate in Alfred:

    gh-auth YOURTOKEN

This will store your token and you will be able to use the following commands:

### Search your repositories

To search your repos, just type in Alfred:

    gh YOUR-REPO-NAME

You'll see a list of matching repositories.  
Actioning a match will open the repository on GitHub.

### Update local cache

To avoid hitting the GitHub API every time you do a search, and to return results faster, the workflow caches all your repositories the first time you do a search. If you create a new repository, you'll need to rebuild your local cache with:

    gh-update

You'll also be offered to update the cache (and repeat the search) if a search returns no results.

# License

This is released under the [MIT License](http://opensource.org/licenses/MIT).

# Feedback

[@edgarjs](http://twitter.com/edgarjs)
