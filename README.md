# bedrock-viz from backups

This project creates a docker image which is intended to be used as part of a wider system running Minecraft Bedrock Server in docker.

## Overview of functions

1. Listen on a MQTT topic for a message saying a backup has been taken.
2. Copy & unzip the backup.
3. Run bedrock-viz to generate map and all html supporting files.
4. rsync map files to web host
5. Send MQTT message to say map has been updated.

## Notes

* Assume a multi-server environment. i.e. more than one BDS running in different containers, with backups saved to a central location.
* Assume all map generation is done in series, not concurrently.
* The current implementation assumes that the time taken to generate maps is shorter than the interval between backup messages.

## _Status_

_My simple test setup works, but on my real Minecraft server bedrock-viz crashes. More work required..._

## Setup

Copy example.env and set environment variables, then use your file in docker.
Or just define environment variables in docker-compose.

Bind volumes:

* `/backups` - the shared volume where backups are saved to.
* `/data` - a persistent volume where this image can save working files and generated maps. (If not set this image will still work but may re-generate existing maps when restarted.)

## Example

For an example docker-compose setup, see <https://github.com/edward3h/docker-bds-integration-test>
