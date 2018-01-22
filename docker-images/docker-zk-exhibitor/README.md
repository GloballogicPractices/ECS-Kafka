Runs an [Exhibitor](https://github.com/Netflix/exhibitor)-managed [ZooKeeper](http://zookeeper.apache.org/) instance using S3 for backups and automatic node discovery.

### NOTE: Customized version of docker Index as [mbabineau/zookeeper-exhibitor](https://index.docker.io/u/mbabineau/zookeeper-exhibitor/):


### Versions
* Exhibitor 1.5.5
* ZooKeeper 3.4.6


Customizations:

- Made EFS directory as a variable parameter provided via ecs task definition
