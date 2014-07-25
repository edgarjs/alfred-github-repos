Quickly find your github repositories from [Alfred](http://www.alfredapp.com/).

# Download from Packal

<http://www.packal.org/workflow/github-repos>


# Usage

### Identify yourself

This workflow search within your public and private repositories (including organizations you belong to). So you need to provide an access token to make things easy.

So go to [create a new personal access token](https://github.com/settings/tokens/new). You can enter any description and it just need to be checked the `repo` option (read private repositories).

![New personal access token](http://cloud.edgar.sh/2z7pq.png)

Then **copy the token** (as it will be visible only that time!). And authenticate in alfred:

    gh-auth YOURTOKEN

This will store your token and you will be able to use the following commands...

### Search your repositories

To search your repos, just type in alfred:

    gh YOUR-REPO-NAME

And that's it, you'll see a list of matching repositories.

### Rebuild local cache

To avoid hitting the github API every time you do a search, and to return results faster, the workflow caches all your repositories the first time you authenticate or do a search. If you create a new repository, you'll need to update your local cache with:

    gh-update

# License

This is released under the [MIT License](http://opensource.org/licenses/MIT).

# Feedback

[@edgarjs](http://twitter.com/edgarjs)
