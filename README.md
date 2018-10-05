# docker_pull

The main idea of the project is to be able to download docker images without docker installed.
The flow has 4 main steps.
1. Getting token for access to a library
2. Getting manifest for a lable which contains certain digest
3. Gettign layer list
4. Downloading layers to a folder named as image name
