Cloning the remote Git repository
Cloning repository https://github.com/yourusername/your-repo
 > git init /var/lib/jenkins/workspace/goldenimage@2 # timeout=10
Fetching upstream changes from https://github.com/yourusername/your-repo
 > git --version # timeout=10
 > git --version # 'git version 2.43.5'
Setting http proxy: 100.65.247.140:3128
 > git fetch --tags --force --progress -- https://github.com/yourusername/your-repo +refs/heads/*:refs/remotes/origin/* # timeout=10
ERROR: Error cloning remote repo 'origin'
hudson.plugins.git.GitException: Command "git fetch --tags --force --progress -- https://github.com/yourusername/your-repo +refs/heads/*:refs/remotes/origin/*" returned status code 128:
stdout: 
stderr: remote: Support for password authentication was removed on August 13, 2021.
remote: Please see https://docs.github.com/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
fatal: Authentication failed for 'https://github.com/yourusername/your-repo/'

	at PluginClassLoader for git-client//org.jenkinsci.plugins.gitclient.CliGitAPIImpl.launchCommandIn(CliGitAPIImpl.java:2852)
	at PluginClassLoader for git-
