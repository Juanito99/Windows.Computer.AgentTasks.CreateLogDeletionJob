## SCOM Agent Task - Create Log Deletion Job

‘Create Log Deletion Job’ is a Management Pack that contains two SCOM – Agent Tasks to tame logfile growth.
•	Create Log Deletion Job creates a scheduled task that deletes log files older than N days on the monitored computer. 
•	Create Log Compress ( + Deletion ) Job creates a scheduled task that compresses files older than N days and optionally also deletes the compressed files older than M days on the monitored computer.
It works on SCOM 2012 R2 and later.


### Introduction:
Many applications and services which run on a server are creating logs. Some are doing it by default and some others are configured to do so by an Administrator or Developer.
To prevent that the logs, occupy the complete disk space either the concerned developer implemented a smart log handling which rotates the files or the Administrator added a
scheduled script to do so. This Management Pack provides a convenient way to create a log deletion job directly out of the SCOM console


### Pictures:
Task in the SCOM Console:
![Task_In_the_Console](https://raw.githubusercontent.com/Juanito99/Windows.Computer.AgentTasks.CreateLogDeletionJob/master/PicturesForGitWebSite/MonitoringPaneShowTaskCompress.png)




### More information on:
[Documentation](https://github.com/Juanito99/Windows.Computer.AgentTasks.CreateLogDeletionJob/blob/master/Documentation/SCOM%20-%20Agent%20Tasks%20-%20Create%20Log%20Compress%20(%20+%20Deletion%20)%20Job.pdf)




### Downloads:
[ManagementPack-Sealed](https://github.com/Juanito99/Windows.Computer.AgentTasks.CreateLogDeletionJob/blob/master/Windows.Computer.AgentTasks.CreateLogDeletionJob/bin/Release/Windows.Computer.AgentTasks.CreateLogDeletionJob.mp) 

[ManagementPack-UnSealed](https://github.com/Juanito99/Windows.Computer.AgentTasks.CreateLogDeletionJob/blob/master/Windows.Computer.AgentTasks.CreateLogDeletionJob/bin/Release/Windows.Computer.AgentTasks.CreateLogDeletionJob.xml)


[Source for VSAE 2017](https://github.com/Juanito99/Windows.Computer.AgentTasks.CreateLogDeletionJob/tree/master/Windows.Computer.AgentTasks.CreateLogDeletionJob)



### Community Management Pack:
Keep this and many other management packs automatically up to date by installing the [Community Management Pack](https://squaredup.com/landing-pages/the-scom-community-mp-catalog)



### License Terms

Windows.Computer.AgentTasks.CreateLogDeletionJob
Copyright (C) 2018 Ruben Zimmermann (Juanito99)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.