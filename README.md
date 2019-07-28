## MangoApps Folder Download (MFD) utility

- what

    - you can use this utility to do a recursive file download of folders in your MangoApps (https://www.mangoapps.com/) account

- why

    - because of the MangoApps web interface limitation:

        - "You can download max of 1 Folder and 100 Files at a time"

    - why not write a program in language X to do this because langauge X is Y?

        - i wanted to use common lisp and docker


- how

    - first log into your MangoApps account in a web browser

    - get the content of the cookie that authenticates you for this session and the folder id of the folder you want to download

    - ![](media/1.png)

    - ![](media/2.png)

    - ![](media/3.png)

    - if your docker ce installation is using the docker hub registry:

        - docker run -it --rm  -v /tmp/output:/mnt  justin2004/mfd ./entry.lisp --cookie "efceb782409fc6c119ab8b85cf53ea70" --folder 6015535

    - if there are no errors then look in /tmp/output for your files

    - then sign out of the MangoApps session in your browser (to invalidate that cookie)


---

### TODO/notes 

- this docker image is already built at: https://hub.docker.com/r/justin2004/mfd/

- quicklisp concerns

- show how to run sbcl with more memory (in case you need to download large files)

- it won't attempt to redownload a file that is already there

- show how to get felix_id in chrome

- note why i didn't implement logon

- not tested with filenames with embedded ../../.. (though outputting to a docker volume should protect your host OS filesystem)
