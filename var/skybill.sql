-- MySQL dump 10.9
--
-- Host: localhost    Database: skybill
-- ------------------------------------------------------
-- Server version	5.1.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Info`
--

DROP TABLE IF EXISTS `Info`;
CREATE TABLE `Info` (
  `Info` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `src_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp') NOT NULL DEFAULT 'tcp',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ts`,`dest`,`src`,`src_port`,`proto`),
  KEY `ts` (`ts`),
  KEY `sp` (`proto`,`src_port`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `cliserv_summary`
--

DROP TABLE IF EXISTS `cliserv_summary`;
CREATE TABLE `cliserv_summary` (
  `day` date NOT NULL DEFAULT '0000-00-00',
  `rate_type` enum('clients','servers') NOT NULL DEFAULT 'clients',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  `items` int(10) unsigned NOT NULL DEFAULT '0',
  `ports` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`day`,`rate_type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `cliserv_summary_details`
--

DROP TABLE IF EXISTS `cliserv_summary_details`;
CREATE TABLE `cliserv_summary_details` (
  `day` date NOT NULL DEFAULT '0000-00-00',
  `rate_type` enum('clients','servers') NOT NULL DEFAULT 'clients',
  `addr` int(10) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp') NOT NULL DEFAULT 'tcp',
  `port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ports_bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  KEY `day` (`day`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `daily`
--

DROP TABLE IF EXISTS `daily`;
CREATE TABLE `daily` (
  `day` date NOT NULL DEFAULT '0000-00-00',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`day`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `destsrc_monthly`
--

DROP TABLE IF EXISTS `destsrc_monthly`;
CREATE TABLE `destsrc_monthly` (
  `year` smallint(5) unsigned NOT NULL DEFAULT '0',
  `month` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `kind` enum('dest','src') NOT NULL DEFAULT 'dest',
  `items` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`year`,`month`,`kind`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `details_daily`
--

DROP TABLE IF EXISTS `details_daily`;
CREATE TABLE `details_daily` (
  `day` date NOT NULL DEFAULT '0000-00-00',
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`day`,`dest`,`src`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `details_monthly`
--

DROP TABLE IF EXISTS `details_monthly`;
CREATE TABLE `details_monthly` (
  `year` smallint(5) unsigned NOT NULL DEFAULT '0',
  `month` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `ip` int(10) unsigned NOT NULL DEFAULT '0',
  `kind` enum('dest','src') NOT NULL DEFAULT 'dest',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`year`,`month`,`kind`,`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ext_ip_unlim`
--

DROP TABLE IF EXISTS `ext_ip_unlim`;
CREATE TABLE `ext_ip_unlim` (
  `ip` int(10) unsigned NOT NULL DEFAULT '0',
  `fake` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `limits`
--

DROP TABLE IF EXISTS `limits`;
CREATE TABLE `limits` (
  `ip` bigint(20) unsigned NOT NULL DEFAULT '0',
  `traffic` bigint(20) DEFAULT NULL,
  `name` varchar(25) NOT NULL DEFAULT '',
  `untimed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `raw`
--

DROP TABLE IF EXISTS `raw`;
CREATE TABLE `raw` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `dest_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `src_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp','gre') NOT NULL DEFAULT 'tcp',
  `bytes` int(10) unsigned NOT NULL DEFAULT '0',
  `packets` mediumint(8) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ts`,`dest`,`dest_port`,`src`,`src_port`,`proto`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `raw_backup`
--

DROP TABLE IF EXISTS `raw_backup`;
CREATE TABLE `raw_backup` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `dest_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `src_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp') NOT NULL DEFAULT 'tcp',
  `bytes` int(10) unsigned NOT NULL DEFAULT '0',
  `packets` mediumint(8) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ts`,`dest`,`dest_port`,`src`,`src_port`,`proto`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `raw_out`
--

DROP TABLE IF EXISTS `raw_out`;
CREATE TABLE `raw_out` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `dest_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `src_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp') NOT NULL DEFAULT 'tcp',
  `bytes` int(10) unsigned NOT NULL DEFAULT '0',
  `packets` mediumint(8) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ts`,`dest`,`dest_port`,`src`,`src_port`,`proto`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `raw_squid`
--

DROP TABLE IF EXISTS `raw_squid`;
CREATE TABLE `raw_squid` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `bytes` int(10) unsigned NOT NULL DEFAULT '0',
  KEY `raw_sq_idx` (`ts`,`dest`,`src`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `servers`
--

DROP TABLE IF EXISTS `servers`;
CREATE TABLE `servers` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dest` int(10) unsigned NOT NULL DEFAULT '0',
  `dest_port` smallint(5) unsigned NOT NULL DEFAULT '0',
  `src` int(10) unsigned NOT NULL DEFAULT '0',
  `proto` enum('tcp','udp','icmp','igmp') NOT NULL DEFAULT 'tcp',
  `bytes` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ts`,`dest`,`dest_port`,`src`,`proto`),
  KEY `ts` (`ts`),
  KEY `dp` (`proto`,`dest_port`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `time_to_limit`
--

DROP TABLE IF EXISTS `time_to_limit`;
CREATE TABLE `time_to_limit` (
  `since` time NOT NULL DEFAULT '00:00:00',
  `till` time NOT NULL DEFAULT '00:00:00',
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

