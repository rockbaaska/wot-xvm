// ������� ����� � ����� ������
var text_sample1="{{wn}}";
var text_replace1="{{eff:4}}";
var text_sample2="{{c:wn}}";
var text_replace2="{{c:eff}}";

// ��� ����� ���� �� ��������� ��� ������ XVM.xvmconf, ���� �������� ����
if (WScript.Arguments.length<1) {
    var file_name="XVM.xvmconf";
}
else {
    file_name=WScript.Arguments(0);
}

var fso=WScript.CreateObject("Scripting.FileSystemObject");
// ��������� �������� ���� �� ���������
var file_name_tmp=file_name+".tmp";
if(fso.FileExists(file_name_tmp))
  fso.DeleteFile(file_name_tmp);
fso.MoveFile(file_name,file_name_tmp);

var fo=fso.OpenTextFile(file_name_tmp,1,false,false);
var fr=fso.OpenTextFile(file_name,2,true,false);

// ��������� ������ ������ � ������ ������
var re1=new RegExp(text_sample1);
var re2=new RegExp(text_sample2);

while(!fo.AtEndOfStream){
  var line=fo.ReadLine();
  var line_replace=line.replace(re1,text_replace1);
  line_replace=line_replace.replace(re1,text_replace1);
  line_replace=line_replace.replace(re2,text_replace2);
  line_replace=line_replace.replace(re2,text_replace2);
  fr.WriteLine(line_replace);
}
fo.Close();
fr.Close();
// ������� �������� ����
fso.DeleteFile(file_name_tmp);