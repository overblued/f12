#SingleInstance, force
#Persistent

iSetInterval("main_key",30)
main_key("\")

main_key(key:=0){
  static defaultCMDKey:="rctrl"
  static cmdkey:="rctrl"
  static keys := ["F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","BS","\","="]
  static intval:={},ids:={}

  if !key {
    if (cmdkey="none" || iKeyState(cmdkey,defaultCMDKey)) {
      for i,key in keys {
        iTrigger(key) && main_key(key)
      }
      return
    }
    if iKeyState("lwin","rwin","alt","shift","ctrl"){              
      return
    }
    for key,value in ids {
      ids_Arr := strsplit(value,",")
      loop % ids_Arr.length()
      {
        i:=ids_Arr[A_Index]
        if WinExist("ahk_id " . i) {
            if ("=" = key){
              iThrottle("iSend",5000,"{ins}",i)
              iSend("{numlock}",i)
              Continue
            }
            if instr(intval[key],"-") {
              m:=strsplit(intval[key],"-")
              min:=m[1]*1000
              max:=m[2]*1000
            } else {
              min := intval[key]*1000
              max := intval[key]*1000
            }
            iThrottle("iSend",iRandom(min,max,6),"{" . key . "}",i)
        } else {
          ids[key]:=StrReplace(value, i,"")
          ids[key]:=RegExReplace(ids[key], ",+",",")
        }
      }
    }

    return
  }
  if (key = "\") {
    optionsPath:=A_ScriptDir . "\f12.txt"
    FileRead options, %optionsPath%
    if not ErrorLevel  ; Successfully loaded.
    {
      changed:=0
      while (c:=iMatch(options,"i)F\d+ [1-9][0-9\-]*")) {
        changed:=1
        ; msgbox % c
        m:=strsplit(c," ")
        intval[m[1]]:=m[2]
        options:=RegExReplace(options,"i)F\d+ [1-9][0-9\-]*","","",1)

      }
      c:=iMatch(options,"i)mod [a-z]+","cmd " . defaultCMDKey)
      cmdkey:=strsplit(c," ")[2]

      iTooltip("settings loaded.")
      return
    }
    iTooltip("default settings loaded.")
    return
  }

  if (key = "BS") {
    currentWindowID:=WinExist("A")
    for k,v in ids {
      ids[k]:=StrReplace(ids[k], currentWindowID, "")
    }
    iTooltip("clear all keys on current window.")
    return
  }

  if key {
    ;switch on/off
    if !intval[key] 
      intval[key]:=1
    if !ids[key]
      ids[key]:=","
    currentWindowID:=WinExist("A")
    if InStr(ids[key],currentWindowID){
      ids[key] := StrReplace(ids[key], currentWindowID, "")
      iTooltip(key . " key Off")
    } else {
      ids[key] := ids[key] . currentWindowID . ","
      iTooltip(key . " key On")
    }
  }
}


iMatch(s,r,fallback:=0){
  m:=""
  RegExMatch(s,r,m)
  if (!m && fallback)
    return fallback
  return m
}

iRandom(min,max,normdist:=1){
  ran:=0
  loop, %normdist% {
    Random, n, min, max
    ran := ran + n
  }
  ran:=ran/normdist
  return Floor(ran)
}


iSend(n, aid:=0){
	if aid {
    if !WinExist("ahk_id" . aid)
      return
    if (aid != WinExist("A")) {
      ControlSend, , %n%, ahk_id %aid%
      return
    }
	}
  SendInput % n
}
iTrigger(keys*){
  static triggered:={}
  k:=iJoin(keys)
  if iKeyState(keys*)
    return !triggered[k] && triggered[k]:=iSetInterval("iTrigger",20,keys*)
  else
    return triggered[k] && triggered[k]:=iSetInterval(triggered[k])
}

iKeyState(params*){
  s := 0
  for key, value in params
  {
    if InStr(value,A_Space)
    {
      temp:=1
      arr := StrSplit(value, A_Space)
      for key2, value2 in arr
      {
        temp := temp && iKeyState_Get(value2)
      }
      s := temp
    } else {
      s := s || iKeyState_Get(value)
    }
    if s
      return value
  }
}

iKeyState_Get(keyname){
  static p:={"capslock":1,"appskey":1}
  return GetKeyState(keyname, p[keyname] ? "P" : 0)
}

iSetInterval(cb:=0, interval:=1000, params*){
	static taskers := {}
  static index := 0
  if !cb {
    ;end routine when there is no task left
    if !taskers.MaxIndex()
      return
    SetTimer, %A_ThisFunc%, -10
    for key, item in taskers
    {
      if A_TickCount - item.lastCalledTime >= item.time
      {
        item.lastCalledTime := A_TickCount
        if item.fn.Call() || item.oneshot
          taskers.Delete(key)
      }
    }
    return
  }
  ;remove
	if taskers[cb] {
    taskers.Delete(cb)
    return 0
	}
  ;add
	if IsFunc(cb){
    if !taskers.MaxIndex()
      SetTimer, %A_ThisFunc%, -10
    index += 1
		taskers[index] := { fn: Func(cb).bind(params*), time: Abs(interval), lastCalledTime: A_TickCount}
    if interval < 0
      taskers[index].oneshot := 1

    return index
	}
}

iTooltip(s:=0){
  static show:=0
  if !s{
    show:=0
    Tooltip
    return
  }

  show:=1
  mousegetpos, x,y
  Tooltip, %s%, x , y-22
  iSetInterval("iTooltip",-2000)

}

iThrottle(fn,time,params*){
  static history:={}
  if IsObject(fn)
    id := &fn
  else
    id := fn
  (time > 0) && (id .= iJoin(params))
  if history[id] && (A_TickCount - history[id] < abs(time))
    return
  history[id] := A_TickCount
  %fn%(params*)
  return 1
}

iJoin(obj,d:=""){
  if !IsObject(obj)
    return obj
  k:=""
  for key, value in obj
  {
    if d && k
      k .= d . value
    else
      k .= value
  }
  return k
}