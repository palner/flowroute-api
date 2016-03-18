/*
# Author: Fred Posner <fred@qxork.com>
# Twitter: @fredposner
# Contact: http://qxork.com
# Date: 2016-03-18
# Copyright: The Palner Group, Inc.
# License: GPLv3
*/

-- create the database (change the username password)
create database flowroute;
grant all on flowroute.* to 'USERNAME'@'localhost' identified by 'AWESOMEPASSWORD';
use flowroute;

-- sample account table
CREATE TABLE `account` (
  `account_id` int NOT NULL AUTO_INCREMENT,
  `friendlyname` varchar(20) NOT NULL DEFAULT '',
  `contact` varchar(50) NOT NULL DEFAULT '',
  `company` varchar(50) NOT NULL DEFAULT '',
  `address` varchar(50) NOT NULL DEFAULT '',
  `city` varchar(25) NOT NULL DEFAULT '',
  `state` varchar(20) NOT NULL DEFAULT '',
  `postalcode` varchar(10) NOT NULL DEFAULT '',
  `country` varchar(10) NOT NULL DEFAULT '',
  `phone` varchar(20) NOT NULL DEFAULT '',
  `email` varchar(65) DEFAULT NULL,
  `shortnote` varchar(80) NOT NULL DEFAULT '',
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`account_id`),
  KEY `friendlyname` (`friendlyname`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- example did table
CREATE TABLE `did` (
  `did_id` int NOT NULL AUTO_INCREMENT,
  `account_id` int NOT NULL DEFAULT '0',
  `did` varchar(20) NOT NULL,
  `active` tinyint NOT NULL DEFAULT '1',
  `shortnote` varchar(20) NOT NULL DEFAULT '',
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`did_id`),
  KEY `did` (`did`),
  KEY `active` (`active`),
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- example sms table
CREATE TABLE `sms` (
  `sms_id` int NOT NULL AUTO_INCREMENT,
  `did_id` int NOT NULL DEFAULT '0',
  `outdid` varchar(20) NOT NULL,
  `message_id` varchar(20) NOT NULL,
  `body` varchar(255) NOT NULL DEFAULT '',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`sms_id`),
  KEY `did_id` (`did_id`),
  KEY `outdid` (`outdid`),
  KEY `message_id` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- stored procedure to check if did exists and then
-- store the message in the database and return the
-- email if did is found. returns 'fail' if did isn't
-- found. checks the last 10 of the did.
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_sms`(
 didvar varchar(20),
 outdidvar varchar(20),
 message_idvar varchar(20),
 bodyvar varchar(20)
)
begin
 declare dididvar int;
 declare emailvar varchar(65);
 if exists (select did_id from did where RIGHT(did, 10) = RIGHT(didvar, 10) and active=1)
 then
  select d.did_id, a.email from did d
  inner join account a on a.account_id = d.account_id
  where RIGHT(d.did,10) = RIGHT(didvar, 10) and d.active = 1
  into dididvar, emailvar;

  insert into sms (did_id, outdid, message_id, body) VALUES (dididvar, outdidvar, message_idvar, bodyvar);

  select emailvar as result;
 else
  select 'fail' as result;
 end if;
end ;;
DELIMITER ;
