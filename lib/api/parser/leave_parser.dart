import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:nkust_ap/models/leave_data.dart';
import 'package:nkust_ap/models/leave_submit_info_data.dart';

/// Extracts hidden input fields from HTML.
///
/// Used to get ASP.NET view state and other hidden form values.
Map<String?, dynamic> hiddenInputGet(String? html, {bool? removeTdElement}) {
  String? rawHtml = html;
  if (removeTdElement == true) {
    const String firstMatchString =
        '<td width="40px" nowrap="nowrap" align="left">';
    const String lastMatchString = '</td>';
    int startIndex = rawHtml!.indexOf(firstMatchString);
    while (startIndex > -1) {
      rawHtml = html!.substring(0, startIndex) +
          html.substring(
            html.indexOf(lastMatchString, startIndex) + lastMatchString.length,
          );
      startIndex = html.indexOf(firstMatchString);
    }
  }

  final Document document = parse(html);
  final Map<String?, dynamic> hiddenData = <String?, dynamic>{};
  final List<Element> inputDom = document.getElementsByTagName('input');
  for (int i = 0; i < inputDom.length; i++) {
    if (inputDom[i].attributes['type'] == 'hidden' &&
        inputDom[i].attributes['name'] != null &&
        inputDom[i].attributes['name']!.substring(0, 1) == '_') {
      hiddenData[inputDom[i].attributes['name']] =
          inputDom[i].attributes['value'] ?? '';
    }
  }
  return hiddenData;
}

/// Extracts all input field values from HTML.
Map<String?, dynamic> allInputValueParser(String? html) {
  final Document document = parse(html);
  final Map<String?, dynamic> hiddenData = <String?, dynamic>{};
  final List<Element> inputDoc = document.getElementsByTagName('input');
  for (int i = 0; i < inputDoc.length; i++) {
    if (inputDoc[i].attributes['name'] != null) {
      hiddenData[inputDoc[i].attributes['name']] =
          inputDoc[i].attributes['value'] ?? '';
    }
  }
  return hiddenData;
}

/// Parses leave query results from HTML.
///
/// Returns a [LeaveData] object with parsed leave records.
LeaveData leaveQueryParser(String? html) {
  final Document document = parse(html);
  final List<Leave> leaves = <Leave>[];
  final List<String> timeCodeList = <String>[];
  final List<Element> tableDom = document.getElementsByClassName('mGridDetail');

  if (tableDom.isEmpty) {
    return LeaveData(leaves: <Leave>[], timeCodes: <String>[]);
  }

  final List<Element> trDom = tableDom[0].getElementsByTagName('tr');

  // Make timeCode list from header row
  final List<Element> th = trDom[0].getElementsByTagName('th');
  for (int i = 4; i < th.length; i++) {
    timeCodeList.add(th[i].text);
  }

  // Parse leave rows
  for (int i = 1; i < trDom.length; i++) {
    final List<Element> td = trDom[i].getElementsByTagName('td');
    final List<LeaveSections> sections = <LeaveSections>[];

    for (int e = 4; e < td.length; e++) {
      if (td[e].text == '　') continue;
      sections.add(
        LeaveSections(
          section: timeCodeList[e - 4],
          reason: td[e].text,
        ),
      );
    }

    leaves.add(
      Leave(
        leaveSheetId: td[1].text,
        date: td[2].text,
        instructorsComment: td[3].text,
        leaveSections: sections,
      ),
    );
  }

  return LeaveData(leaves: leaves, timeCodes: timeCodeList);
}

/// Parses leave submit info from HTML.
///
/// Returns a [LeaveSubmitInfoData] object with available leave types,
/// time codes, and default tutor information.
LeaveSubmitInfoData? leaveSubmitInfoParser(String? html) {
  final Document document = parse(html);

  // Parse time codes from grid header
  List<String> timeCodeList = <String>[];
  final List<Element> grids = document.getElementsByClassName('mGrid');

  if (grids.isNotEmpty) {
    final List<Element> timeCode = grids[0]
        .getElementsByTagName('tr')[0]
        .getElementsByTagName('th');
    if (timeCode.length > 5) {
      for (int i = 3; i < timeCode.length; i++) {
        timeCodeList.add(timeCode[i].text);
      }
    }
  } else {
    // Default time codes if grid not found
    timeCodeList = <String>[
      'M', '1', '2', '3', '4', 'A', '5', '6', '7', '8', '9', '10', '11', '12',
      '13',
    ];
  }

  // Parse leave types
  final List<Type> leaveTypes = <Type>[];
  final List<Element> leaveTypeList =
      document.getElementsByClassName('aspNetDisabled');

  if (leaveTypeList.length <= 1) {
    return null;
  }

  for (int i = 1; i < leaveTypeList.length; i++) {
    final List<Element> labels =
        leaveTypeList[i].getElementsByTagName('label');
    final List<Element> inputs =
        leaveTypeList[i].getElementsByTagName('input');
    if (labels.isEmpty) continue;

    leaveTypes.add(
      Type(
        title: labels[0].text,
        id: inputs[0].attributes['value'].toString(),
      ),
    );
  }

  // Parse default tutor
  Tutor? tutorData;
  final Element? tutorSelect =
      document.getElementById('ContentPlaceHolder1_CK001_ddlTeach');

  if (tutorSelect != null) {
    final List<Element> tutorOptions =
        tutorSelect.getElementsByTagName('option');
    for (int i = 1; i < tutorOptions.length; i++) {
      if (tutorOptions[i].attributes['selected'] != null) {
        tutorData = Tutor(
          name: tutorOptions[i].text,
          id: tutorOptions[i].attributes['value'] ?? '',
        );
        break;
      }
    }
  }

  return LeaveSubmitInfoData(
    tutor: tutorData,
    type: leaveTypes,
    timeCodes: timeCodeList,
  );
}
