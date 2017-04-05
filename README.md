# SS_Containers
This project provides Docker containers designed to be used during deployment:
* [secure-tomcat-image](secure-tomcat-image) provides a base Tomcat servlet container image for hosting WAR projects
* [redis-image](redis-image) provides a Redis key-value store image for easy clustering in a deployed environment
* [rabbit-image](rabbit-image) provides a RabbitMQ AMQP image for easy clustering in a deployed environment

## Security
Note that the redis-image and rabbit-image are designed to be run behind a firewall and are not secured.  If exposed
to the internet, they must first be secured.
The secure-tomcat-image is designed to be exposed to the internet on port 8080 only.
