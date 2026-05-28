"""
Генератор .docx шаблонов для BlackListPlus.
Запуск: python3 tool/generate_templates.py
Складывает .docx в assets/templates/.
"""
import os
from pathlib import Path

from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "templates"
OUT_DIR.mkdir(parents=True, exist_ok=True)

DISCLAIMER = (
    "ВНИМАНИЕ. Документ является шаблоном-заготовкой для самостоятельного "
    "заполнения. Не является юридической консультацией. Юридическую силу "
    "приобретает только после собственноручного подписания сторонами на "
    "бумажном носителе в соответствии с законодательством Российской "
    "Федерации (ст. 808 ГК РФ — для расписок). Перед использованием "
    "рекомендуется проконсультироваться с квалифицированным юристом."
)


def _add_instruction(
    doc: Document,
    *,
    when_to_use: str,
    who_signs: str,
    copies: str,
    what_next: str,
) -> None:
    """Добавляет короткий блок 'Инструкция по заполнению' перед документом.
    Эту страницу пользователь может удалить перед распечаткой."""
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title_run = title.add_run("ИНСТРУКЦИЯ ПО ЗАПОЛНЕНИЮ")
    title_run.bold = True
    title_run.font.size = Pt(12)
    title_run.font.color.rgb = RGBColor(0x00, 0x7D, 0x88)

    def _line(label: str, body: str) -> None:
        p = doc.add_paragraph()
        run_label = p.add_run(f"• {label}: ")
        run_label.bold = True
        run_label.font.size = Pt(10)
        run_body = p.add_run(body)
        run_body.font.size = Pt(10)

    _line("Когда использовать", when_to_use)
    _line("Кто подписывает", who_signs)
    _line("Количество экземпляров", copies)
    _line("Что делать дальше", what_next)

    hint = doc.add_paragraph()
    hint_run = hint.add_run(
        "Перед распечаткой данную страницу с инструкцией можно удалить."
    )
    hint_run.italic = True
    hint_run.font.size = Pt(9)
    hint_run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

    doc.add_page_break()


def _set_base_style(doc: Document) -> None:
    style = doc.styles["Normal"]
    style.font.name = "Times New Roman"
    style.font.size = Pt(12)

    section = doc.sections[0]
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.5)


def _add_disclaimer(doc: Document) -> None:
    p = doc.add_paragraph()
    run = p.add_run(DISCLAIMER)
    run.italic = True
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    doc.add_paragraph()


def _add_title(doc: Document, text: str) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(text)
    run.bold = True
    run.font.size = Pt(14)


def _add_para(doc: Document, text: str, *, align=WD_ALIGN_PARAGRAPH.JUSTIFY) -> None:
    p = doc.add_paragraph()
    p.alignment = align
    p.add_run(text)


def _add_field_line(doc: Document, label: str) -> None:
    p = doc.add_paragraph()
    p.add_run(f"{label}: ").bold = True
    p.add_run("_" * 60)


def _add_signature_block(doc: Document, role_left: str, role_right: str) -> None:
    doc.add_paragraph()
    table = doc.add_table(rows=2, cols=2)
    table.autofit = True

    table.cell(0, 0).paragraphs[0].add_run(f"{role_left}:").bold = True
    table.cell(0, 1).paragraphs[0].add_run(f"{role_right}:").bold = True

    sig_left = table.cell(1, 0).paragraphs[0]
    sig_left.add_run("_" * 25 + " / __________________")
    sig_right = table.cell(1, 1).paragraphs[0]
    sig_right.add_run("_" * 25 + " / __________________")

    note = doc.add_paragraph()
    note_run = note.add_run("(подпись / расшифровка)")
    note_run.italic = True
    note_run.font.size = Pt(9)
    note_run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)


def build_raspiska() -> None:
    doc = Document()
    _set_base_style(doc)
    _add_instruction(
        doc,
        when_to_use=(
            "При передаче денег в долг между физическими лицами. По ст. 808 "
            "ГК РФ письменная форма обязательна, если сумма превышает 10 000 ₽."
        ),
        who_signs=(
            "Только заёмщик. Расписка составляется от его лица, и его подпись "
            "подтверждает факт получения денежных средств. Подпись займодавца "
            "не требуется."
        ),
        copies=(
            "1 экземпляр. Оригинал хранится у займодавца до момента возврата "
            "долга."
        ),
        what_next=(
            "После возврата долга займодавец возвращает оригинал расписки "
            "заёмщику или составляет встречную расписку о получении возврата. "
            "Нотариальное удостоверение не обязательно, но повышает "
            "доказательную силу при судебном разбирательстве."
        ),
    )
    _add_disclaimer(doc)

    _add_title(doc, "ДОЛГОВАЯ РАСПИСКА")
    doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.add_run("г. ____________________   « ___ » ______________ 20__ г.")
    doc.add_paragraph()

    _add_para(
        doc,
        "Я, _________________________________________________________________________ "
        "(ФИО полностью), «___» __________ ______ года рождения, паспорт серии "
        "________ № ____________, выдан _______________________________________ "
        "«___» __________ ______ года, зарегистрирован(а) по адресу: "
        "_____________________________________________________________________________, "
        "далее именуемый «Заёмщик»,",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "получил(а) от _____________________________________________________________ "
        "(ФИО полностью), «___» __________ ______ года рождения, паспорт серии "
        "________ № ____________, выдан _______________________________________ "
        "«___» __________ ______ года, зарегистрирован(ой) по адресу: "
        "_____________________________________________________________________________, "
        "далее именуемого «Займодавец»,",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "денежные средства в сумме ________________________ "
        "(______________________________________________________ прописью) рублей "
        "00 копеек в качестве займа.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "Обязуюсь вернуть указанную сумму в срок до «___» __________ 20__ года.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "Денежные средства получены мной полностью в момент подписания "
        "настоящей расписки. Претензий по сумме и срокам не имею.",
    )
    doc.add_paragraph()

    _add_signature_block(doc, "Заёмщик", "Займодавец")

    out = OUT_DIR / "dolgovaya_raspiska.docx"
    doc.save(out)
    print(f"  ✓ {out.name}")


def build_akt() -> None:
    doc = Document()
    _set_base_style(doc)
    _add_instruction(
        doc,
        when_to_use=(
            "Используется как приложение к договору займа или расписке для "
            "отдельной фиксации факта передачи наличных средств."
        ),
        who_signs=(
            "Обе стороны — передающая и принимающая. Подписи обязательны от "
            "обоих участников."
        ),
        copies=(
            "2 экземпляра — по одному у каждой стороны, имеют одинаковую "
            "юридическую силу."
        ),
        what_next=(
            "Хранится как приложение к основному документу (договору займа "
            "или расписке). Используется как доказательство факта передачи "
            "денежных средств."
        ),
    )
    _add_disclaimer(doc)

    _add_title(doc, "АКТ ПРИЁМА-ПЕРЕДАЧИ ДЕНЕЖНЫХ СРЕДСТВ")
    doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.add_run("г. ____________________   « ___ » ______________ 20__ г.")
    doc.add_paragraph()

    _add_para(
        doc,
        "Мы, нижеподписавшиеся:",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "Передающая сторона: ___________________________________________ (ФИО), "
        "паспорт серии ________ № ____________, выдан _________________________, "
        "зарегистрирован(а) по адресу: _________________________________________,",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "Принимающая сторона: __________________________________________ (ФИО), "
        "паспорт серии ________ № ____________, выдан _________________________, "
        "зарегистрирован(а) по адресу: _________________________________________,",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "составили настоящий акт о нижеследующем:",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "1. Передающая сторона передала, а Принимающая сторона приняла "
        "денежные средства в сумме ________________________ "
        "(_____________________________________________________ прописью) рублей.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "2. Основание передачи: _________________________________________________ "
        "_____________________________________________________________________________.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "3. Денежные средства переданы наличными в полном объёме. "
        "Стороны взаимных претензий по сумме и порядку передачи не имеют.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "4. Настоящий акт составлен в двух экземплярах, по одному для каждой "
        "из сторон, имеющих одинаковую юридическую силу.",
    )
    doc.add_paragraph()

    _add_signature_block(doc, "Передал", "Принял")

    out = OUT_DIR / "akt_priema_peredachi.docx"
    doc.save(out)
    print(f"  ✓ {out.name}")


def build_uvedomlenie() -> None:
    doc = Document()
    _set_base_style(doc)
    _add_instruction(
        doc,
        when_to_use=(
            "Когда заёмщик не вернул долг в установленный срок. Это "
            "досудебная стадия — обязательная попытка урегулирования спора "
            "до обращения в суд."
        ),
        who_signs=(
            "Только кредитор (отправитель). Подпись должника не требуется — "
            "это одностороннее требование."
        ),
        copies=(
            "2 экземпляра — один отправляется должнику заказным письмом, "
            "второй (с почтовой квитанцией о вручении) остаётся у кредитора "
            "как доказательство соблюдения досудебного порядка."
        ),
        what_next=(
            "Отправить заказным письмом с описью вложения и уведомлением о "
            "вручении по адресу регистрации должника. Сохранить почтовую "
            "квитанцию. Если в указанный срок ответа не последует — можно "
            "подавать иск в суд по месту жительства должника (ст. 28 ГПК РФ)."
        ),
    )
    _add_disclaimer(doc)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.add_run("Кому: _____________________________________").bold = True
    p2 = doc.add_paragraph()
    p2.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p2.add_run("(ФИО получателя)")
    p3 = doc.add_paragraph()
    p3.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p3.add_run("Адрес: _____________________________________")
    doc.add_paragraph()

    p4 = doc.add_paragraph()
    p4.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p4.add_run("От: ________________________________________").bold = True
    p5 = doc.add_paragraph()
    p5.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p5.add_run("(ФИО отправителя)")
    p6 = doc.add_paragraph()
    p6.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p6.add_run("Адрес: _____________________________________")
    p7 = doc.add_paragraph()
    p7.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p7.add_run("Телефон: ___________________________________")
    doc.add_paragraph()

    _add_title(doc, "УВЕДОМЛЕНИЕ (ТРЕБОВАНИЕ) О ВОЗВРАТЕ ДОЛГА")
    doc.add_paragraph()

    _add_para(
        doc,
        "Между нами «___» __________ 20__ года был заключён договор займа "
        "(долговая расписка), согласно которому я передал(а) Вам в долг "
        "денежные средства в сумме ________________________ "
        "(_____________________________________________________ прописью) рублей "
        "на срок до «___» __________ 20__ года.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "На дату составления настоящего уведомления сумма долга Вами не "
        "возвращена, чем нарушены условия договора займа и нормы ст. 810 "
        "Гражданского кодекса РФ.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "На основании изложенного, требую в срок не позднее «___» __________ "
        "20__ года возвратить мне сумму долга в полном объёме в размере "
        "________________________ рублей.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "В случае невозврата указанной суммы в установленный срок оставляю "
        "за собой право обратиться в суд с требованием о взыскании суммы "
        "долга, процентов за пользование чужими денежными средствами по "
        "ст. 395 ГК РФ, а также судебных расходов.",
    )
    doc.add_paragraph()

    _add_para(
        doc,
        "Перевод денежных средств прошу осуществить по следующим реквизитам: "
        "_____________________________________________________________________________ "
        "_____________________________________________________________________________.",
    )
    doc.add_paragraph()

    p = doc.add_paragraph()
    p.add_run("Приложения:").bold = True
    doc.add_paragraph("1. Копия долговой расписки / договора займа от «___» __________ 20__ г.")
    doc.add_paragraph()

    p_date = doc.add_paragraph()
    p_date.add_run("« ___ » ______________ 20__ г.")
    doc.add_paragraph()

    p_sig = doc.add_paragraph()
    p_sig.add_run("Подпись: ").bold = True
    p_sig.add_run("_" * 25 + " / __________________")
    note = doc.add_paragraph()
    note_run = note.add_run("(подпись / расшифровка)")
    note_run.italic = True
    note_run.font.size = Pt(9)
    note_run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

    out = OUT_DIR / "uvedomlenie_o_vozvrate.docx"
    doc.save(out)
    print(f"  ✓ {out.name}")


def main() -> None:
    print(f"Генерация шаблонов в {OUT_DIR.relative_to(ROOT)}/")
    build_raspiska()
    build_akt()
    build_uvedomlenie()


if __name__ == "__main__":
    main()
