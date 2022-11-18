# tests/update

This is used to perform a large number of updates to a target.  It creates three
versions of an update bundle and then iteratively updates the target.

## Base Requirements
* `python3`
* `python3-pip`
* `python3-venv`

### Optional
* `curl` - If you are running this with power cycling and using the default power cycle method
you will need `curl` installed.

## Getting Started
1. Setup a virtual environment.  From this directory:
    ```
    python3 -m venv .venv
    source .venv/bin/activate
    ```
2. Install dependencies.
    ```
    python3 -m pip install -r requirements.txt
    ```
3. See the program options.
    ```
    ./update.py --help 
    ```
4. Figure out the IP address of the target and run the program.
    ```
    ./update.py -t <IP_ADDRESS> -n <NUM_UPDATES>
    ```

After doing the three builds of the update software it will continuously perform updates.  You should
see something like:
```
----- Test iteration 94 -----
Current slot versions: [2, 0]
Updating slot 0 using version 1.
Finished posting update.
Power cycling after 4.14 seconds.
Test iteration 94 successful.
----- Test iteration 95 -----
Current slot versions: [2, 0]
Updating slot 0 using version 1.
Finished posting update.
Power cycling after 7.37 seconds.
Test iteration 95 successful.
----- Test iteration 96 -----
Current slot versions: [2, 0]
Updating slot 0 using version 1.
Finished posting update.
Test iteration 96 successful.
```

## Useful Options
If you've already run the script and generated the three update bundles you can save time on
subsequent runs by using the `-w` option and specifying the directory that contains the three
update bundles.

## Power Cycling

This test allows for power cycling the target during the update, on a random basic of occurence
and a random time in the update that the power cycle should be performed.  The actual power cycle
command can be passed to the `update.py` script, but likely should just be an executable shell
script.

The software default is to call the [power_cycle.sh](./power_cycle.sh) script, which uses a
["Control by Web"](https://www.controlbyweb.com/webrelay/) relay on a 192.168.1.X subnet.

Note that power cycles are not performed on the first two updates since those need to complete in
order for both slots on the target to be populated with known versions of the software.
