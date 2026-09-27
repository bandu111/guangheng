from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
p=r"C:\Users\bandu\Desktop\黑客松比赛材料\光衡_GuangHeng_Anker黑客松预赛提交材料_20页优化版(1).docx"
d=Document(p)
for i,x in enumerate(d.paragraphs):
    if i>=130:
        print(i, x.style.name, x.text.encode('unicode_escape').decode())
print('--- BODY BLOCKS LAST 45 ---')
blocks=[]
for child in d.element.body.iterchildren():
    if child.tag.endswith('}p'):
        obj=Paragraph(child,d)
        text=obj.text
        blocks.append(('P',obj.style.name,text))
    elif child.tag.endswith('}tbl'):
        obj=Table(child,d)
        text=' | '.join(c.text.replace('\n',' / ') for r in obj.rows for c in r.cells)
        blocks.append(('T','',text))
for i,(kind,style,text) in list(enumerate(blocks))[-55:]:
    print(i,kind,style,text[:180].encode('unicode_escape').decode())
