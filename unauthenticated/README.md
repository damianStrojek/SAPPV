# How-to

If you want it to work with the script `run-Invoke-mgmt-con-soap.sh` you have to change following lines in `powersap/Standalone/soap/Invoke-mgmt-con-soap.ps1`:

Add this to line 17:

```pwsh
# Second arg should be destination port
[parameter(Mandatory=$true)]
[string]$port,
```

Change `$url` to:

```pwsh
$url = 'http://'+$target+':'+$port
```
