#@Powershell -NoP -W Hidden -C "$PSCP='%~f0';$PSSR='%~dp0'.TrimEnd('\');&([ScriptBlock]::Create((gc '%~f0'|?{$_.ReadCount -gt 1}|Out-String)))" %* & exit/b
# by earthdiver1  V1.05
if ($PSCommandPath) {
    $PSCP = $PSCommandPath
    $PSSR = $PSScriptRoot
    $code = '[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd,int nCmdShow);'
    $type = Add-Type -MemberDefinition $code -Name Win32ShowWindowAsync -PassThru
    [void]$type::ShowWindowAsync((Get-Process -PID $PID).MainWindowHandle,0) }
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$menuItem = New-Object System.Windows.Forms.MenuItem "Exit"
$menuItem.add_Click({$notifyIcon.Visible=$False;while(-not $status.IsCompleted){Start-Sleep 1};$appContext.ExitThread()})
$contextMenu = New-Object System.Windows.Forms.ContextMenu
$contextMenu.MenuItems.AddRange($menuItem)
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.ContextMenu = $contextMenu
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSCP)
$notifyIcon.Text = (Get-ChildItem $PSCP).BaseName
$notifyIcon.Visible = $True
$_syncHash = [hashtable]::Synchronized(@{})
$_syncHash.NI   = $notifyIcon
$_syncHash.PSCP = $PSCP
$_syncHash.PSSR = $PSSR
$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions  = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("_syncHash",$_syncHash)
$scriptBlock = Get-Content $PSCP | ?{ $on -or $_[1] -eq "!" }| %{ $on=1; $_ } | Out-String
$action=[ScriptBlock]::Create(@'
#   param($Param1, $Param2)
    Start-Transcript -LiteralPath ($_syncHash.PSCP -Replace '\..*?$',".log") -Append
    Function Start-Sleep { [CmdletBinding(DefaultParameterSetName="S")]
        param([parameter(Position=0,ParameterSetName="M")][Int]$Milliseconds,
              [parameter(Position=0,ParameterSetName="S")][Int]$Seconds,[Switch]$NoExit)
        if ($PsCmdlet.ParameterSetName -eq "S") {
            $int = 5
            for ($i = 0; $i -lt $Seconds; $i += $int) {
                if (-not($NoExit -or $_syncHash.NI.Visible)) { exit }
                Microsoft.PowerShell.Utility\Start-Sleep -Seconds $int }
        } else {
            $int = 100
            for ($i = 0; $i -lt $Milliseconds; $i += $int) {
                if (-not($NoExit -or $_syncHash.NI.Visible)) { exit }
                Microsoft.PowerShell.Utility\Start-Sleep -Milliseconds $int }}}
    $script:PSCommandPath = $_syncHash.PSCP
    $script:PSScriptRoot  = $_syncHash.PSSR
'@ + $scriptBlock)
$PS = [PowerShell]::Create().AddScript($action) #.AddArgument($Param1).AddArgument($Param2)
$PS.Runspace = $runspace
$status = $PS.BeginInvoke()
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
exit
#! ---------- ScriptBlock (Line No. 28) begins here ---------- DO NOT REMOVE THIS LINE


# .NET Frameworkの宣言
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

#key判定
$HUI = $Host.UI.RawUI
$keystates = [System.Management.Automation.Host.ControlKeyStates]
$modifier = $keystates::LeftCtrlPressed -bor $keystates::RightCtrlPressed
$keymap = [System.Windows.Forms.Keys]

# Windows APIの宣言
$signature='[DllImport("user32.dll",CharSet=CharSet.Auto,CallingConvention=CallingConvention.StdCall)]public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);'
$SendMouseClick = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru
$position = [System.Windows.Forms.Cursor]::Position  

function mouse_click([int]$ix, [int]$iy) {
    echo $ix, $iy
    $position.X = $ix
    $position.Y = $iy
    # マウスカーソル移動
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($position.X,$position.Y)

    # クリックイベント生成
    $SendMouseClick::mouse_event(0x0002, 0, 0, 0, 0);
    $SendMouseClick::mouse_event(0x0004, 0, 0, 0, 0);
}


echo "start"

$index = 0
$stopFlag = $false

while(-not $stopFlag){
    #write-host "Processing..."
    while($HUI.KeyAvailable){
        $keyinput = $HUI.Readkey("NoEcho,IncludeKeyUp")
        if (($keyinput.VirtualKeycode -eq $keymap::T) -and ($keyinput.ControlKeyState -band $modifier)){
            $index++
            $index %=4
            #echo $index
            switch($index){
                0{
                    echo "0"
                    mouse_click 100 20
                }
                1{
                    echo "1"
                    mouse_click 300 200
                
                }
                2{
                    echo "2"
                    mouse_click 500 200
                }
                3{
                    echo "3"
                    mouse_click 600 200
                }
            }
            break
        }
    }
}