#!/usr/bin/bash

DT=`date '+%Y%m%d_%H%M%S'`
echo $DT ## 테스트
function print_fnc {
echo " "
printf "================================================================\n"
echo $1 - `date +"%Y%m%d_%H%M%S"`
printf "================================================================\n"
echo " "
}

function master_mon
{
print_fnc "1. mysql process check"
ps -ef | egrep "mysqld_safe|mysql" |grep -v grep

print_fnc "2. file system usage check"
df -k /data

print_fnc "3. binary log size check"

ls -lrt /data/snuh/binlog* | awk '{print $7, $5}' \
| awk '{arr[$1]+=$2} END {for (i in arr) {print  i, arr[i]/1024/1024/1024, "GB"}} '

print_fnc "4. mariadb error log check"
tail -1000 /data/snuh/logdir/error.log | grep -i error #/data/snuh/logdir/error.log

print_fnc "5. mariadb master status check"
mysql -u root -p -e "show global status
where Variable_name in
('uptime', 'Max_used_connections',
'Threads_connected', 'Aborted_connects', 'Open_tables',
'innodb_row_lock_waits', 'innodb_buffer_pool_wait_free',
'select_full_join', 'Created_tmp_disk_tables'
);" 

}

function slave_mon
{ 
#read -p "Are you sure checking in slave db? " -n 1 -r

print_fnc "1. mariadb backup size check"
du -sh /data/dailybackup/*

print_fnc "2. mariadb backup log check"
grep -i error /data/dailybackup/backup.log

print_fnc "3. mariadb slave status check"
#mysql -u root -p -e "show slave status\G" > /root/tmp.txt
mysql -u root -p -e "show slave status\G"  | egrep -i 'running|error|connection|pos'
#egrep -i 'running|error|connection|pos' /root/tmp.txt

}

### Main ###

if [ $# -ge 1 ]
then
    SRV=$1
#    echo $1
else
    echo "Usage: maria_mon.sh m or maria_mon.sh s"
    SRV='X'
#    read -p "please input M(master) or S(salve): " SRV
#    exit;
fi

while true
do

    if [ $SRV == 'M' ] || [ $SRV == 'm' ] || [ $SRV == 'S' ] || [ $SRV == 's' ]
    then 
        if [ $SRV == 'M' ] || [ $SRV == 'm' ]
        then
#            print_fnc "Master monitoring start"
            master_mon
        elif [ $SRV == 'S' ] || [ $SRV == 's' ]
        then
#            print_fnc "Slave monitoring start"
            slave_mon
        else
            echo "please input M(m) or S(s)"
        fi

        break

    else
        read -p "please input M(master) or S(salve): " SRV
        continue
    fi
done
