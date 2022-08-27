Attribute VB_Name = "modPub"
Option Explicit
Public strAppPath As String 'Ӧ�ó���Ŀ¼
Public strSetFile As String
Public strSet As String
Public strDataFile As String
Public strData As String
Public isHasCreateIcon As Boolean
Public strInfo As String
Public strInitData As String
Public lngCurrentIndex As Long  '��ǰid

Public lngLeftLatest&, lngTopLatest& '���µ����ꡣ

Public isFormAllLoadCompleted As Boolean
Public isFirstNote As Boolean '�Ƿ��ǵ�һ��

Public Declare Function ChooseColor Lib "comdlg32.dll" Alias "ChooseColorA" (pChoosecolor As ChooseColor) As Long
Private Declare Function MoveWindow Lib "user32" (ByVal hwnd As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal bRepaint As Long) As Long
Private Declare Function timeGetTime Lib "winmm.dll" () As Long
Public Declare Function SetParent Lib "user32" (ByVal hWndChild As Long, ByVal hWndNewParent As Long) As Long

's,n,h,d,m,yyyy
Public Type ShijianDanwei
    strTag As String 'h
    strName As String 'ʱ
    strNameShow As String 'չʾ�����ƣ��������ճ��Ľз�
    lngSeconds As Long
End Type

Type ChooseColor
     lStructSize As Long
     hwndOwner As Long
     hInstance As Long
     rgbResult As Long
     lpCustColors As String
     flags As Long
     lCustData As Long
     lpfnHook As Long
     lpTemplateName As String
End Type
Public tDanwei(6) As ShijianDanwei

Public Const NOTE_DEFAULT_WIDTH = 4395 '��ǩĬ�Ͽ��
Public Const NOTE_DEFAULT_HEIGHT = 3615 '��ǩĬ�ϸ߶�
Public Const NEW_NOTE_MOVE_RIGHT = 320 '�±�ǩ
Public Const NEW_NOTE_MOVE_DOWN = 570

Public lngHwndDesktop As Long '����ľ��
Public isNeedSetToDesktop As Boolean '�Ƿ���Ҫ����Ƕ�뵽����

Sub Main()
    Dim w As New clsWindow
    If App.PrevInstance Then '��ֹ�ظ�����
        w.GetWindowByTitle("WeNote", 1).Focus  '������ǰ�Ѿ�������Ĵ��ڼ�����ʾ
        End
    End If

    strAppPath = App.Path
    If Right(strAppPath, 1) <> "\" Then strAppPath = strAppPath & "\"
    
    strInfo = "WeNote | ΢��ǩ V" & App.Major & "." & App.Minor & "." & App.Revision & vbCrLf & vbCrLf & _
        "  ����:sysdzw" & vbCrLf & _
        "  ��ҳ:https://blog.csdn.net/sysdzw" & vbCrLf & _
        "  Q  Q:171977759" & vbCrLf & _
        "  ����:sysdzw@163.com" & vbCrLf & vbCrLf & _
        "2020-01-20"
    Call initDanwei
    
    lngHwndDesktop = w.GetWindowByClassName("Progman", 1).hwnd  '�õ�������
    isNeedSetToDesktop = isSetToDesktop()
    
    Load frmStartup
    strDataFile = strAppPath & "����.txt"
    strData = fileStr(strDataFile)
    If strData <> "" Then
        Dim vLine, i%, j%
        vLine = Split(strData, vbCrLf)
        For i = 0 To UBound(vLine)
            If vLine(i) <> "" Then
                lngCurrentIndex = Split(vLine(i), vbTab)(0) '����id
                strInitData = vLine(i)
                Call NewNote
            End If
        Next
    Else
        isFirstNote = True
        Call NewNote
    End If
    isFormAllLoadCompleted = True
End Sub
'���һ����ǩ
Private Sub NewNote()
    Dim frmNewNote As New frmNote
    Load frmNewNote
End Sub
'��ʼ��ʱ�䵥λ
Private Sub initDanwei()
    Dim vTag, vName, vNameShow, vJinweiBefore, vJinweiAfter, vSeconds, i%
    vTag = Split("s,n,h,d,m,yyyy", ",")
    vName = Split("��,��,ʱ,��,��,��", ",")
    vNameShow = Split("��,����,Сʱ,��,��,��", ",")
    vSeconds = Split("1,60,3600,86400,2592000,31104000,31536000", ",")
    For i = 0 To UBound(vTag)
        tDanwei(i).strTag = vTag(i)
        tDanwei(i).strName = vName(i)
        tDanwei(i).strNameShow = vNameShow(i)
        tDanwei(i).lngSeconds = vSeconds(i)
    Next
End Sub
'�õ���λ������
Public Function getDanweiIndex(ByVal strDanweiName$) As Integer
    Dim v, i%, intDanwei%
    For i = 0 To UBound(tDanwei)
        If tDanwei(i).strName = strDanweiName Or tDanwei(i).strNameShow = strDanweiName Then
            getDanweiIndex = i
            Exit Function
        End If
    Next
End Function
'����combobox�߶�
Public Sub setComboHeight(oComboBox As ComboBox, lNewHeight As Long)
    Dim oldscalemode As Integer
    Dim lngLeft&, lngTop&, lngWidth&
    lngLeft = oComboBox.Left
    lngTop = oComboBox.Top
    lngWidth = oComboBox.Width
    If TypeOf oComboBox.Parent Is Frame Then Exit Sub
    oldscalemode = oComboBox.Parent.ScaleMode
    oComboBox.Parent.ScaleMode = vbPixels
    MoveWindow oComboBox.hwnd, lngLeft \ 15, lngTop \ 15, lngWidth \ 15, lNewHeight, 1
    oComboBox.Parent.ScaleMode = oldscalemode
End Sub
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'���ܣ����������ļ���������ֱ��д�ļ�
'��������writeToFile
'��ڲ���(����)��
'  strFileName �������ļ�����
'  strContent Ҫ���뵽�����ļ����ַ���
'  isCover �Ƿ񸲸Ǹ��ļ���Ĭ��Ϊ����
'����ֵ��True��False���ɹ��򷵻�ǰ�ߣ����򷵻غ���
'��ע��sysdzw �� 2007-5-2 �ṩ
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Function writeToFile(ByVal strFileName$, ByVal strContent$, Optional isCover As Boolean = True) As Boolean
    On Error GoTo err1
    Dim fileHandl%
    fileHandl = FreeFile
    If isCover Then
        Open strFileName For Output As #fileHandl
    Else
        Open strFileName For Append As #fileHandl
    End If
    Print #fileHandl, strContent
    Close #fileHandl
    writeToFile = True
    Exit Function
err1:
    writeToFile = False
End Function
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'���ܣ������������ļ��������ļ�������
'��������fileStr
'��ڲ���(����)��
'  strFileName �������ļ�����
'����ֵ���ļ�������
'��ע��sysdzw �� 2007-5-3 �ṩ
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Function fileStr(ByVal strFileName As String) As String
    On Error GoTo err1
    Dim lFile&
    lFile = FreeFile
    Open strFileName For Input As #lFile
    fileStr = StrConv(InputB$(LOF(lFile), #lFile), vbUnicode)
    Close #lFile
    Do While InStr(fileStr, vbCrLf & vbCrLf) > 0
        fileStr = Replace$(fileStr, vbCrLf & vbCrLf, vbCrLf)
    Loop
    If Left(fileStr, 2) = vbCrLf Then fileStr = Mid(fileStr, 3)
    If Right(fileStr, 2) = vbCrLf Then fileStr = Left(fileStr, Len(fileStr) - 2)
    Exit Function
err1:
'    MsgBox "�����ڸ��ļ�����ļ����ܷ��ʣ�" & vbCrLf & strFileName, vbExclamation
End Function
Public Function regGetStrSub1(ByVal strData$, strPattern$) As String
     Dim reg As Object
     Dim matchs As Object, match As Object
    
     Set reg = CreateObject("vbscript.regexp")
     reg.Global = True
     reg.IgnoreCase = True
     reg.Pattern = strPattern
    
     Set matchs = reg.Execute(strData$)
     If matchs.Count >= 1 Then
         regGetStrSub1 = matchs(0).SubMatches(0)
     End If
End Function
'5���� ��1�롢1�� �ȵ�
'�õ�����ƥ������н���������Ʊ�������ûس�����
Public Function regGetStrSubAll(ByVal strData$, strPattern$) As String
     Dim reg As Object
     Dim matchs As Object, match As Object, i As Integer, j As Integer
    
     Set reg = CreateObject("vbscript.regexp")
     reg.Global = True
     reg.IgnoreCase = True
     reg.Pattern = strPattern

    Set matchs = reg.Execute(strData)
    For i = 0 To matchs.Count - 1
        For j = 0 To matchs(i).SubMatches.Count - 1
           regGetStrSubAll = regGetStrSubAll & matchs(i).SubMatches(j) & vbTab
        Next
        If Right(regGetStrSubAll, 1) = vbTab Then regGetStrSubAll = Left(regGetStrSubAll, Len(regGetStrSubAll) - 1)
        regGetStrSubAll = regGetStrSubAll & vbCrLf
    Next
    If Right(regGetStrSubAll, 2) = vbCrLf Then regGetStrSubAll = Left(regGetStrSubAll, Len(regGetStrSubAll) - 2)
End Function
'��������ַ��������滻���÷��ο���regReplace("fas7f897fsa9fsd0f8", "\d+", "")
Public Function regReplace(ByVal strData$, strPattern$, strNewString$) As String
    Dim reg As Object
    Set reg = CreateObject("vbscript.regExp")
    reg.Global = True
    reg.IgnoreCase = True
    reg.MultiLine = True
    reg.Pattern = strPattern
    regReplace = reg.Replace(strData, strNewString)
    Set reg = Nothing
End Function
'��������ַ������в����Ƿ�ƥ�䣬�÷��ο���regTest("13895554788", "^\d{11}$")
Public Function regTest(ByVal strData$, strPattern$) As Boolean
    Dim reg As Object
    Set reg = CreateObject("vbscript.regExp")
    reg.Global = True
    reg.IgnoreCase = True
    reg.MultiLine = True
    reg.Pattern = strPattern
    regTest = reg.Test(strData)
    Set reg = Nothing
End Function
'��ʱ����λΪ����
Public Function Wait(ByVal MilliSeconds As Long)
    Dim dSavetime As Double
    dSavetime = timeGetTime + MilliSeconds   '���¿�ʼʱ��ʱ��
    While timeGetTime < dSavetime 'ѭ���ȴ�
        DoEvents 'ת�ÿ���Ȩ���Ա��ò���ϵͳ�����������¼�
    Wend
End Function
'����Ƿ����õ�����
Public Function isSetToDesktop() As Boolean
    If GetSetting("WeNote", "Set", "SetToDesktop") = "" Then
        isSetToDesktop = False
    Else
        isSetToDesktop = (GetSetting("WeNote", "Set", "SetToDesktop") = "1")
        
    End If
End Function
