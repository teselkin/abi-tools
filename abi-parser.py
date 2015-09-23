#!/usr/bin/python


import json
import sys



class SymbolInfo(object):
    catalog = {}
    def __init__(self, index, data):
        self.name = data.get('ShortName', None)
        self.header_file = data.get('Header', None)
        self.line_no = data.get('Line', None)
        self.return_type = data.get('Return', None)
        self.source_file = data.get('Source', None)
        self.source_line = data.get('SourceLine', None)
        self.registers = []
        for key in sorted(data.get('Reg', {})):
            self.registers.append(data['Reg'][key])
        self.params = []
        for key in sorted(data.get('Param', {})):
            self.params.append(data['Param'][key])
        self.catalog[index] = self

    def __str__(self):
        col = []
        col.append('name=%s'  % self.name)
        arr = []
        for item in self.params:
            arr.append('<%s> %s' % (self.resolve_type(item['type']),
                                    item.get('name', '')))
        col.append('params=%s' % ','.join(arr))
        col.append('registers=%s' % ','.join(self.registers))
        col.append('return_type=<%s>' % self.resolve_type(self.return_type))
        return ';'.join(col)

    def resolve_type(self, type_id):
        if type_id in TypeInfo.catalog:
            return TypeInfo.catalog[type_id].name 
        else:
            return type_id




class TypeInfo(object):
    catalog = {}
    def __init__(self, index, data):
        self.name = data.get('Name', None)
        self.type_name = data.get('Type', None)
        self.header_file = data.get('Header', None)
        self.line_no = data.get('Line', None)
        self.type_size = data.get('Size', None)
        self.return_type = data.get('Return', None)
        self.members = []
        for key in sorted(data.get('Memb', {})):
            self.members.append(data['Memb'][key])
        self.params = []
        for key in sorted(data.get('Param', {})):
            self.params.append(data['Param'][key])
        self.catalog[index] = self

    def __str__(self):
        col = []
        col.append('name=%s'  % self.name)
        col.append('type_name=%s' % self.type_name)
        arr = []
        if self.type_name == 'Enum':
            for item in self.members:
                arr.append('%s:%s' % (
                    item['name'], item['value']))
        elif self.type_name == 'Struct':
            for item in self.members:
                arr.append('<%s> %s' % (self.resolve_type(item['type']),
                                        item.get('name', '')))
        col.append('members=%s' % ','.join(arr))
        col.append('return_type=<%s>' % self.resolve_type(self.return_type))
        return ';'.join(col)

    def resolve_type(self, type_id):
        if type_id in self.catalog:
            return self.catalog[type_id].name 
        else:
            return type_id


ifile = sys.argv[1]

dump = {}
with open(ifile) as f:
    dump = json.load(f)

for key in dump.get('TypeInfo'):
    t = TypeInfo(key, dump['TypeInfo'][key])

for key in dump.get('SymbolInfo'):
    t = SymbolInfo(key, dump['SymbolInfo'][key])


for item in SymbolInfo.catalog.values():
        print str(item)

