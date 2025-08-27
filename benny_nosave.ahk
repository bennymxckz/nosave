; #############################################################################
; #                                                                           #
; #    ██████╗ ███████╗███╗   ██╗███╗   ██╗██╗   ██╗                           #
; #    ██╔══██╗██╔════╝████╗  ██║████╗  ██║╚██╗ ██╔╝                           #
; #    ██████╔╝█████╗  ██╔██╗ ██║██╔██╗ ██║ ╚████╔╝                            #
; #    ██╔══██╗██╔══╝  ██║╚██╗██║██║╚██╗██║  ╚██╔╝                             #
; #    ██████╔╝███████╗██║ ╚████║██║ ╚████║   ██║                              #
; #    ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═══╝   ╚═╝                              #
; #                                                                           #
; #############################################################################

; =============================================================================
;  CONFIGURATION
; =============================================================================

; --- IP Address to block.
global TargetIP := "192.81.241.171"

; --- Sound files to use for feedback.
; --- Leave blank ("") to use default beeps.
global SoundFile_On := A_WinDir . "\Media\Speech On.wav"
global SoundFile_Off := A_WinDir . "\Media\Speech Sleep.wav"

; --- Hotkeys to toggle the block.
; --- ^ = Ctrl | ! = Alt | + = Shift | # = Win
global Hotkey_Block := "^F9"  ; Default: Ctrl+F9
global Hotkey_Allow := "^F12" ; Default: Ctrl+F12


; =============================================================================
;  INITIALIZATION & SCRIPT SETTINGS
; =============================================================================
#NoEnv
#Persistent
#SingleInstance Force
#InstallKeybdHook
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

global RuleName := "AHK_Rockstar_Block_" . A_TickCount
global isBlocked := false

if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; --- Apply the hotkeys from the configuration
Hotkey, %Hotkey_Block%, BlockIP
Hotkey, %Hotkey_Allow%, AllowIP


; =============================================================================
;  GUI & SYSTEM TRAY
; =============================================================================
Gui, Status:New, +LastFound +AlwaysOnTop -Caption +ToolWindow, Rockstar Connection Status
Gui, Status:Color, 2C2F33, 23272A
Gui, Status:Font, s10 w600, Segoe UI
Gui, Status:Margin, 15, 15
Gui, Status:Add, Text, w180 cFFFFFF vStatusIndicator, * ALLOWED
Gui, Status:Font, s8 w400, Segoe UI
Gui, Status:Add, Text, w180 c99AAB5 y+5, (Click and drag to move)
Gui, Status:Font, c28A745, Segoe UI
GuiControl, Status:Font, StatusIndicator
Gui, Status:Show, x10 y10 NoActivate, Rockstar Connection Status
WinSet, Transparent, 230, Rockstar Connection Status
OnMessage(0x201, "WM_LBUTTONDOWN")

Menu, Tray, NoStandard
Menu, Tray, Add, Toggle Block, ToggleBlockHandler
Menu, Tray, Add, Show/Hide Status, ToggleStatusWindow
Menu, Tray, Add
Menu, Tray, Add, Exit, AppExitHandler
TrayTipText := "Rockstar Connection Toggler" . "`n" . "(" . Hotkey_Block . " to Block, " . Hotkey_Allow . " to Allow)"
Menu, Tray, Tip, %TrayTipText%
Menu, Tray, Default, Toggle Block

SetTimer, HideStatusWindow, -5000 ; Hide the window 5 seconds after startup

return ; *** END OF AUTO-EXECUTE SECTION ***


; =============================================================================
;  CORE FUNCTIONS
; =============================================================================
BlockIP() {
    global
    if (isBlocked)
        return
    SetTimer, HideStatusWindow, Off ; Cancel any pending timer to hide the window
    Gui, Status:Show, NoActivate    ; Ensure the window is visible
    WinSet, Transparent, 230, Rockstar Connection Status
    RunWait, %comspec% /c netsh advfirewall firewall add rule name="%RuleName%" dir=out action=block remoteip="%TargetIP%",, hide
    isBlocked := true
    UpdateStatusWindow("BLOCKED", "DC3545")
    if (SoundFile_On && FileExist(SoundFile_On))
        SoundPlay, %SoundFile_On%, wait
    else
        SoundBeep, 750, 150
}

AllowIP() {
    global
    if (!isBlocked)
        return
    RunWait, %comspec% /c netsh advfirewall firewall delete rule name="%RuleName%",, hide
    isBlocked := false
    Gui, Status:Show, NoActivate ; Show the window to confirm the change
    WinSet, Transparent, 230, Rockstar Connection Status
    UpdateStatusWindow("ALLOWED", "28A745")
    SetTimer, HideStatusWindow, -5000 ; Set a timer to hide the window in 5 seconds
    if (SoundFile_Off && FileExist(SoundFile_Off))
        SoundPlay, %SoundFile_Off%, wait
    else
        SoundBeep, 1000, 150
}

UpdateStatusWindow(statusText, hexColor) {
    Gui, Status:Default
    Gui, Font, c%hexColor%, Segoe UI
    GuiControl, Font, StatusIndicator
    GuiControl,, StatusIndicator, * %statusText%
}

WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2,,, Rockstar Connection Status
}


; =============================================================================
;  EVENT HANDLERS & EXIT ROUTINE
; =============================================================================
OnExit("AppExit")

HideStatusWindow:
    Loop, 230
    {
        WinSet, Transparent, % 230 - A_Index, Rockstar Connection Status
        Sleep, 2
    }
    Gui, Status:Hide
return

ToggleBlockHandler:
    if (isBlocked)
        AllowIP()
    else
        BlockIP()
return

ToggleStatusWindow:
    WinGet, Style, Style, Rockstar Connection Status
    if (Style & 0x10000000)
        Gui, Status:Hide
    else
    {
        Gui, Status:Show, NoActivate
        WinSet, Transparent, 230, Rockstar Connection Status
    }
return

AppExitHandler:
    AppExit()
return

AppExit() {
    RunWait, %comspec% /c netsh advfirewall firewall delete rule name="%RuleName%",, hide
    ExitApp
}
