#! /bin/ksh

# $DOWNLOADS\create_devops.sh


# =======================================
# USAGE: 
# =======================================
# Log in to the PM server as oracle
# Create a new subdirectory, without any files in it, and switch to that subdirectory. e.g. 
#   mkdir -pv /apg/patch/devops
#   cd /apg/patch/devops
# vi  /apg/patch/devops/create_devops.sh 
#   Cut and paste the text from this file into vi, using 'INSERT' mode.
#   :wq!
# chmod 777 create_devops.sh
# time ./create_devops.sh
# Send   devops_$CUSTOMER_ID.zip   back to PM Support. 
#
# OPTIONAL: Clean Up
#   cd /apg/patch
#   rm -r /apg/patch/devops


# ========================================================
# Check user
# ========================================================
# If I am not oracle, then exit. 
if [ `whoami` != "oracle" ] ; then 
    echo "### ERROR: You need to be oracle to run this script."
    exit 1
fi 

# ========================================================
# SETUP:   
# ========================================================

# LOGDIR="/apg/update/pdsprod"
LOGDIR="."

# Set DEBUGGING=1 to enable debugging. 
DEBUGGING=0
CHECK_FILE=0

# e -- encrypt with a password 
# ZIP_PARAMS="-emv"
ZIP_PARAMS="-mv"
# ZIP_PARAMS="-v"

DATE_THRESHOLD="TO_DATE('2018-12-31', 'YYYY-MM-DD')"
SYSLOG_THRESHOLD="TO_DATE('2019-12-31', 'YYYY-MM-DD')"


#-- set PAGESIZE to zero to suppress all headings, page breaks, titles, the initial blank line, and other formatting information.
#-- set colsep "|"    -- column separator
SQLPLUS_CFG="set pagesize 0
set linesize 32767 
    -- max length of output line
set heading on
set head on
set verify off    
    -- no output of parameter replacements
set feedback off  
    -- no xx rows selected at the bottom
set echo off
set trimspool on  
    -- no line-padding
set tab ON
set recsep off
set colsep |
set newpage none
set termout off   
    -- no console output
column assigned_uid format 999999999999.9
column DBIDENTITY format 9999999999999999
column COMMON_ID format 999999999999.9
column CREATE_USER_ID format 999999999999.9
column DATA_SET_ID format 999999999999.9
column DL_ENTRY_ID format 999999999999.9
column DL_ID format 999999999999.9
column ED_PARENT_ABSTRACT_CLASS_ID format 999999999999.9
column ED_PARENT_CLASS_ID format 999999999999.9
column ENTERPRISE_ID format 999999999999.9
column ENTITY_ID format 999999999999.9
column FACILITY_ID format 999999999999.9
column FACILITY_TYPE_ID format 999999999999.9
column FISCAL_PERIODICITY_DEF_ID format 999999999999.9
column FISCAL_PERIODICITY_ID format 999999999999.9
column FOLDER_ID format 999999999999.9
column FOLDER_LIBRARY_ID format 999999999999.9
column HCFA_TYPE_ID format 999999999999.9
column HISTORY_ID format 999999999999.9
column IM_JOB_RUN_ID format 999999999999.9
column LAST_CHANGE_USER_ID format 999999999999.9
column MB_DEFINITION_ID format 999999999999.9
column OPER_PRACT_ROLE_ID format 999999999999.9
column OWNER_ID format 999999999999.9
column PAYROLL_PERIODICITY_DEF_ID format 999999999999.9
column PAYROLL_PERIODICITY_ID format 999999999999.9
column PERSIST_CLASS_ID format 999999999999.9
column SAMPLE_ID format 999999999999.9
column SPECIALTY_ID format 999999999999.9
column STAGING_AREA_PERSIST_CLASS_ID format 999999999999.9
column TAX_CD_TYPE_ID format 999999999999.9
column UNIQUE_ID format 999999999999.9
column USER_ID format 999999999999.9
column WD_ID format 999999999999.9
column WS_ID format 999999999999.9

"

ORACLE_SID=pdsprod

#echo "### INFO:   Please enter your customer identifier (e.g. 12345), and then press ENTER"
#read CUSTOMER_ID


# ========================================================
# remove devops.zip if it exists: 
# ========================================================

rm -f $LOGDIR/devops.zip

# ========================================================
# EXTRACT RAW DATA: 
# ========================================================
# dm.pl(csv) via HPM_LOGFILE directory object, or just to '/apg/update/pdsprod'
if [ $DEBUGGING -eq 1 ] ; then 
#------------------------------------------------
touch $LOGDIR/devops_file1.txt
touch $LOGDIR/devops_file2.txt

$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > test.txt
    set linesize 32767
    set pagesize 50000
    -- column unique_id format 999999999999.9
    -- column history_id format 999999999999.9
    -- column wd_id format 999999999999.9
    SET NUMFORMAT 999999999999.9
    select * from support.worksheet;
SCRIPT
ls -l test.txt
head test.txt
tail test.txt
#------------------------------------------------
else


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
TABLENAME="system_info"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG

    GRANT INHERIT PRIVILEGES ON USER SYS TO SUPPORT
/
    select host_name, instance_name, version as oracle_version, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS PM') as timestamp from v\$instance;
    select support.pds.latest() from dual;
    select assigned_uid from support.dsw_uid;
SCRIPT
ls -l `which java`  >> $LOGDIR/$TABLENAME.txt
echo " " >> $LOGDIR/$TABLENAME.txt
ls -l /usr/java >> $LOGDIR/$TABLENAME.txt
echo " " >> $LOGDIR/$TABLENAME.txt
java -version >> $LOGDIR/$TABLENAME.txt   2>&1
echo " " >> $LOGDIR/$TABLENAME.txt
uname -a >> $LOGDIR/$TABLENAME.txt
echo " " >> $LOGDIR/$TABLENAME.txt
nslookup `hostname`   >> $LOGDIR/$TABLENAME.txt
echo " " >> $LOGDIR/$TABLENAME.txt
if [ -f /etc/os-release ] ; then 
    cat /etc/os-release >> $LOGDIR/$TABLENAME.txt
fi

ls -l $LOGDIR/${TABLENAME}.txt
cat $LOGDIR/${TABLENAME}.txt


# ------------------------------------------------------------------------------
# UID_CUSTID_DSWUID.txt
# ------------------------------------------------------------------------------
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/test.txt
set feedback off
set pagesize 0
column assigned_uid format 999999999999.9
select * from support.dsw_uid;
SCRIPT
# trim(dsw_uid)
DSW_UID=`cat $LOGDIR/test.txt | awk '{$1=$1};1'`
DSW_UID_FILE="UID_${CUSTOMER_ID}_${DSW_UID}.txt"
mv -f $LOGDIR/test.txt $LOGDIR/$DSW_UID_FILE

# ------------------------------------------------------------------------------
TABLENAME="table_descriptions"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    select 'SYSTEMLOG' from dual;
    desc support.SYSTEMLOG;
    select 'WD' from dual;
    desc support.WD;
    select 'WORKSHEET' from dual;
    desc support.WORKSHEET;
    select 'HISTORY' from dual;
    desc support.HISTORY;
    select 'IM_RUN_INSTANCE' from dual;
    desc support.IM_RUN_INSTANCE;
    select 'PDS_VERSION' from dual;
    desc support.PDS_VERSION;
    select 'PATCH_GROUP' from dual;
    desc support.PATCH_GROUP;
    select 'SYSTEMLOGCODEDESCRIPTORS' from dual;
    desc support.SYSTEMLOGCODEDESCRIPTORS;
    select 'ENTITY' from dual;
    desc support.ENTITY;
    select 'FACILITY' from dual;
    desc support.FACILITY;
    select 'DATA_SET_PHYS' from dual;
    desc support.DATA_SET_PHYS;
    select 'EXTERNAL_SYSTEM' from dual;
    desc support.EXTERNAL_SYSTEM;
    select 'SECPRINCIPAL' from dual;
    desc support.SECPRINCIPAL;
    select 'MB_APPLY_HISTORY' from dual;
    desc support.MB_APPLY_HISTORY;
    select 'extended_data_definition' from dual;
    desc support.extended_data_definition;
    select 'SAFE_DATA_MART' from dual;
    desc support.SAFE_DATA_MART;
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="systemlog"
QUERY="select DBIDENTITY,DBTIMESTAMP,WASCACHED,SYSTEMLOGDATETIME,SYSLOGACTIVITYTYPE,SYSLOGACTIVITYCODE,SYSTEMLOGAPPLICATIONNAME,SYSTEMLOGUSERID,SYSTEMLOGLOCATION,
'\"'||SYSLOGACTIVITYDATA1||SYSLOGACTIVITYDATA2||SYSLOGACTIVITYDATA3||SYSLOGACTIVITYDATA4||'\"' as syslogactivitydata
 from support.SYSTEMLOG where SYSTEMLOGDATETIME > $SYSLOG_THRESHOLD"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# DEBUGGING
# head $LOGDIR/$TABLENAME.txt
# exit

# ------------------------------------------------------------------------------
TABLENAME="wd"
QUERY="select HISTORY_ID, NAME from support.WD"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="worksheet"
QUERY="select HISTORY_ID, NAME from support.WORKSHEET"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="history"
QUERY="select * from support.HISTORY where LAST_CHANGE_DATE > $DATE_THRESHOLD"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# DEBUGGING -- exit


# ------------------------------------------------------------------------------
TABLENAME="im_run_instance"
QUERY="select * from support.IM_RUN_INSTANCE where RUN_START_DATE > $DATE_THRESHOLD"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="pds_version"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="patch_group"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="systemlogcodedescriptors"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="enterprise"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="entity"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="facility"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="data_set_phys"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="external_system"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="secprincipal"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="mb_apply_history"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="extended_data_definition"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
TABLENAME="safe_data_mart"
QUERY="select * from support.${TABLENAME}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba << SCRIPT > $LOGDIR/$TABLENAME.txt
    $SQLPLUS_CFG
    ${QUERY};
SCRIPT
ls -l $LOGDIR/${TABLENAME}.txt
if [ $CHECK_FILE -eq 1 ] ; then 
    head $LOGDIR/${TABLENAME}.txt
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------


fi
    
# ========================================================
# zip raw data files with removal to devops.zip
# ========================================================
CUSTOMER_ID=$(cat $LOGDIR/enterprise.txt | cut -d '|' -f 4| cut -c2-9)
if [ $DEBUGGING -eq 1 ] ; then 
    zip ${ZIP_PARAMS} $LOGDIR/devops.zip \
        $LOGDIR/devops_file1.txt \
        $LOGDIR/devops_file2.txt
else
    zip ${ZIP_PARAMS} "$LOGDIR/devops_${CUSTOMER_ID}.zip" \
        $LOGDIR/system_info.txt \
        $LOGDIR/$DSW_UID_FILE \
        $LOGDIR/table_descriptions.txt \
        $LOGDIR/systemlog.txt \
        $LOGDIR/wd.txt \
        $LOGDIR/worksheet.txt \
        $LOGDIR/history.txt \
        $LOGDIR/im_run_instance.txt \
        $LOGDIR/pds_version.txt \
        $LOGDIR/patch_group.txt \
        $LOGDIR/systemlogcodedescriptors.txt \
        $LOGDIR/enterprise.txt \
        $LOGDIR/entity.txt \
        $LOGDIR/facility.txt \
        $LOGDIR/data_set_phys.txt \
        $LOGDIR/external_system.txt \
        $LOGDIR/secprincipal.txt \
        $LOGDIR/mb_apply_history.txt \
        $LOGDIR/extended_data_definition.txt \
        $LOGDIR/safe_data_mart.txt
fi

# ========================================================
# List contents of "$LOGDIR/devops_${CUSTOMER_ID}.zip"
# ========================================================
unzip -l "$LOGDIR/devops_${CUSTOMER_ID}.zip"

echo "  "
echo "====================================================================================="
echo "### INFO:  Please send    '$LOGDIR/devops_${CUSTOMER_ID}.zip'    back to PM Support. "
echo "====================================================================================="
echo "  "

