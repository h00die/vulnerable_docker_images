import zipfile, io, sys

sar = '/opt/james/apps/james.sar'
buf = io.BytesIO()

with zipfile.ZipFile(sar, 'r') as zin:
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zout:
        for name in zin.namelist():
            data = zin.read(name)
            if name.endswith('config.xml'):
                data = data.replace(b'!changeme!', b'root')
            zout.writestr(name, data)

buf.seek(0)
with open(sar, 'wb') as f:
    f.write(buf.read())

print("Patched james.sar: admin password is now root/root")
