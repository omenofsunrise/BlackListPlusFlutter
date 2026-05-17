class DocumentTemplate {
  final String id;
  final String title;
  final String shortDescription;
  final String assetPath;
  final String fileName;
  final String whenToUse;
  final List<String> fieldsToFill;
  final String whoSigns;
  final String copies;
  final String whatNext;
  final String? legalNote;

  const DocumentTemplate({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.assetPath,
    required this.fileName,
    required this.whenToUse,
    required this.fieldsToFill,
    required this.whoSigns,
    required this.copies,
    required this.whatNext,
    this.legalNote,
  });
}

const List<DocumentTemplate> kDocumentTemplates = [
  DocumentTemplate(
    id: 'raspiska',
    title: 'Долговая расписка',
    shortDescription:
        'Бланк расписки о получении денежных средств в долг между физическими лицами.',
    assetPath: 'assets/templates/dolgovaya_raspiska.docx',
    fileName: 'Dolgovaya_raspiska.docx',
    whenToUse:
        'При передаче денег в долг между физическими лицами. По ст. 808 ГК РФ '
        'письменная форма обязательна, если сумма превышает 10 000 ₽.',
    fieldsToFill: [
      'Город и дата составления',
      'ФИО, дата рождения, паспорт и адрес заёмщика',
      'ФИО, дата рождения, паспорт и адрес займодавца',
      'Сумма займа цифрами и прописью',
      'Дата возврата долга',
    ],
    whoSigns:
        'Только заёмщик. Расписка составляется от его лица, и его подпись '
        'подтверждает факт получения денежных средств. Подпись займодавца '
        'не требуется.',
    copies:
        '1 экземпляр. Оригинал хранится у займодавца до момента возврата долга.',
    whatNext:
        'После возврата долга займодавец возвращает оригинал расписки '
        'заёмщику или составляет встречную расписку о получении возврата.',
    legalNote:
        'Нотариальное удостоверение не обязательно, но повышает '
        'доказательную силу при судебном разбирательстве.',
  ),
  DocumentTemplate(
    id: 'akt',
    title: 'Акт приёма-передачи денежных средств',
    shortDescription:
        'Бланк акта о передаче наличных. Используется как приложение к расписке или договору.',
    assetPath: 'assets/templates/akt_priema_peredachi.docx',
    fileName: 'Akt_priema-peredachi.docx',
    whenToUse:
        'Как приложение к договору займа или расписке для отдельной '
        'фиксации факта передачи наличных средств.',
    fieldsToFill: [
      'Город и дата',
      'Паспортные данные передающей стороны',
      'Паспортные данные принимающей стороны',
      'Сумма цифрами и прописью',
      'Основание передачи (договор / расписка с реквизитами)',
    ],
    whoSigns:
        'Обе стороны — передающая и принимающая. Подписи обязательны от '
        'обоих участников.',
    copies:
        '2 экземпляра — по одному у каждой стороны, имеют одинаковую '
        'юридическую силу.',
    whatNext:
        'Хранится как приложение к основному документу. Используется как '
        'доказательство факта передачи денежных средств.',
  ),
  DocumentTemplate(
    id: 'uvedomlenie',
    title: 'Уведомление о возврате долга',
    shortDescription:
        'Досудебное уведомление-требование о возврате денежных средств по расписке.',
    assetPath: 'assets/templates/uvedomlenie_o_vozvrate.docx',
    fileName: 'Uvedomlenie_o_vozvrate.docx',
    whenToUse:
        'Когда заёмщик не вернул долг в установленный срок. Это досудебная '
        'стадия — обязательная попытка урегулирования спора до обращения в суд.',
    fieldsToFill: [
      'ФИО и адрес должника (получателя)',
      'ФИО, адрес и телефон кредитора (отправителя)',
      'Реквизиты исходной расписки или договора (дата, сумма)',
      'Новый крайний срок возврата',
      'Реквизиты для перевода средств',
    ],
    whoSigns:
        'Только кредитор (отправитель). Подпись должника не требуется — это '
        'одностороннее требование.',
    copies:
        '2 экземпляра — один отправляется должнику заказным письмом, второй '
        '(с почтовой квитанцией о вручении) остаётся у кредитора как '
        'доказательство соблюдения досудебного порядка.',
    whatNext:
        'Отправить заказным письмом с описью вложения и уведомлением о '
        'вручении по адресу регистрации должника. Сохранить почтовую '
        'квитанцию.',
    legalNote:
        'Если в указанный срок ответа не последует — можно подавать иск '
        'в суд по месту жительства должника (ст. 28 ГПК РФ).',
  ),
];
