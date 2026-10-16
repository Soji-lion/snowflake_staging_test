source buildScriptVar.sh
podman build --progress plain --target broker --tag snowflake-broker --build-arg SNOWFLAKE_REPO=$SNOWFLAKE_REPO --build-arg SNOWFLAKE_REPO_ANCHOR=$SNOWFLAKE_REPO_ANCHOR .
podman build --progress plain --target proxy --tag snowflake-proxy --build-arg SNOWFLAKE_REPO=$SNOWFLAKE_REPO --build-arg SNOWFLAKE_REPO_ANCHOR=$SNOWFLAKE_REPO_ANCHOR .
podman build --progress plain --target tor-server --tag snowflake-server --build-arg SNOWFLAKE_REPO=$SNOWFLAKE_REPO --build-arg SNOWFLAKE_REPO_ANCHOR=$SNOWFLAKE_REPO_ANCHOR .
podman build --progress plain --target fileserver --tag snowflake-fileserver --build-arg SNOWFLAKE_REPO=$SNOWFLAKE_REPO --build-arg SNOWFLAKE_REPO_ANCHOR=$SNOWFLAKE_REPO_ANCHOR .
