if [ $# -ne 1 ]; then
    echo $0: usage: final.sh email
    exit 1
fi

key1=$(tsk -k $1 2>&1 | grep 'Key:' | sed 's/.*Key: //')
echo "1 KEY: ${key1}"

tsk -s 1 -k $key1

#START OF TASK 2
sudo rm /home/hh-school/-r
#END OF TASK 2

tsk -s 1 -k $key1 --check
key2=$(tsk -s 1 -k $key1 --check 2>&1 | grep 'Key:' | sed 's/.*Key: //')
echo "2 KEY: ${key2}"

tsk -s 2 -k $key2

#START OF TASK 2
COUNTER=0
function task_2_parse_log_line {
    if [[ $1 == "[404]" ]] ;
    then
        COUNTER=$((COUNTER + 1))
        echo "$5"
        size=$(sed 's:^.\(.*\):\1:' <<< $5)
        echo $size
        file="$4"
        echo $file
        sudo mkdir -p "${file%/*}"
        sudo fallocate -l $size "$file"
        rights=$(cut -c 2-5 <<< "$3")
        sudo chmod "$rights" "$file"
        echo $rights
    fi
}

function task_2_read_files {
    while IFS='' read -r line || [[ -n "$line" ]]; do
        task_2_parse_log_line $line
    done < "$1"
}

for file in /var/log/loggen/*.log
do
    task_2_read_files "$file"
done
#END OF TASK 2

key3=$(tsk -s 2 -k $key2 --check 2>&1 | grep 'Key:' | sed 's/.*Key: //')
echo "3 KEY: ${key3}"

#START OF TASK 3
processId=$(tsk -s 3 -k $key3 2>&1 | grep -m 1 'PID=' | sed 's:^.*PID=\([0-9]*\),.*:\1:')
echo "processId=${processId}"

echo 'PS AX BEFORE:'
ps ax | grep $processId
time sleep 0.5

kill -s USR1 "$processId"
time sleep 0.02
kill -s USR2 "$processId"
time sleep 0.02
kill -s INT "$processId"

echo 'PS AX AFTER:'
ps ax | grep $processId
time sleep 0.5

sudo ln -s '/var/log/challenge/done.key' /home/hh-school/

#END OF TASK 3

key4=$(tsk -s 3 -k $key3 --check 2>&1 | grep 'Key:' | sed 's/.*Key: //')

#STARD OF TASK 4

header=$(tsk -s 4 -k $key4 2>&1 | grep -m 1 'X-Request' | sed 's/.*header to //')

credentials=$(curl -i -H "X-Request-ID: ${header}" localhost:9182/task1 | grep 'X-Credentials:' | sed 's/.*: //' | tr -d '\r')

function new_location_from_response {
    resp=$1
    echo $(echo "${resp#\r}" | grep Location | sed 's/.*Location: //' | sed 's/\/\?task2\///')
}

cmd="curl -i -F 'credentials=${credentials}' localhost:9182/task2"
echo "init cmd = $cmd"

response=$(eval $cmd)
echo "first response: ${response}"

endpoint=$(new_location_from_response "$response")
echo "first redirect endpoint: ${endpoint}"

newcmd="${cmd}/${endpoint}"
newcmd=${newcmd%$'\r'}
echo "new url:: ${newcmd}"
response=$(eval $newcmd)

redirect_counter=1
while [[ $response == *"307"* ]]; do
    redirect_counter=$((redirect_counter+1))
    echo "new response: ${response}"
    endpoint=$(new_location_from_response "$response")
    echo "new endpoint: ${endpoint}"
    newcmd="${cmd}/${endpoint}"
    newcmd=${newcmd%$'\r'}
    echo "next url: ${newcmd}"
    response=$(eval $newcmd)
done

echo "redirect counter: ${redirect_counter}"
echo "final response: ${response}"

curl -X 'DELETE' localhost:9182/task3/${redirect_counter}

#END OF TASK 4

key5=$(tsk -s 4 -k $key4 --check 2>&1 | grep 'Key:' | sed 's/.*Key: //')

echo "LAST KEY:${key5}"

keys_file='/home/hh-school/final_keys.info'
touch $keys_file

echo $key1 >> $keys_file
echo $key2 >> $keys_file
echo $key3 >> $keys_file
echo $key4 >> $keys_file
echo $key5 >> $keys_file


echo 'FINAL KEYS:'
cat $keys_file
