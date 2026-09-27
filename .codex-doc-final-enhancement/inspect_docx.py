from pathlib import Path

from docx import Document


SOURCE = Path(r"C:\Users\bandu\Desktop\黑客松比赛材料\光衡_GuangHeng_Anker黑客松预赛提交材料_20页优化版(1).docx")


def main() -> None:
    document = Document(SOURCE)
    print("TABLE INDEX")
    for index, table in enumerate(document.tables):
        cell_text = " | ".join(
            cell.text.replace("\n", " / ")
            for row in table.rows
            for cell in row.cells
        )
        print(f"T{index:02d}|{len(table.rows)}x{len(table.columns)}|{cell_text[:260]}")
    print("BODY INDEX")
    page = 1
    for index, element in enumerate(document.element.body):
        tag = element.tag.split("}")[-1]
        text = "".join(element.xpath(".//w:t/text()")).strip()
        page_breaks = len(
            element.xpath('.//w:br[@w:type="page"]')
        )
        print(
            f"{index:03d}|page={page:02d}|type={tag}|breaks={page_breaks}|{text[:180]}"
        )
        page += page_breaks


if __name__ == "__main__":
    main()
