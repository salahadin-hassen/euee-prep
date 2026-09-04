// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GradesTable extends Grades with TableInfo<$GradesTable, Grade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, level];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades';
  @override
  VerificationContext validateIntegrity(Insertable<Grade> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grade(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
    );
  }

  @override
  $GradesTable createAlias(String alias) {
    return $GradesTable(attachedDatabase, alias);
  }
}

class Grade extends DataClass implements Insertable<Grade> {
  final int id;
  final int level;
  const Grade({required this.id, required this.level});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<int>(level);
    return map;
  }

  GradesCompanion toCompanion(bool nullToAbsent) {
    return GradesCompanion(
      id: Value(id),
      level: Value(level),
    );
  }

  factory Grade.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grade(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<int>(json['level']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<int>(level),
    };
  }

  Grade copyWith({int? id, int? level}) => Grade(
        id: id ?? this.id,
        level: level ?? this.level,
      );
  Grade copyWithCompanion(GradesCompanion data) {
    return Grade(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grade(')
          ..write('id: $id, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, level);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grade && other.id == this.id && other.level == this.level);
}

class GradesCompanion extends UpdateCompanion<Grade> {
  final Value<int> id;
  final Value<int> level;
  const GradesCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
  });
  GradesCompanion.insert({
    this.id = const Value.absent(),
    required int level,
  }) : level = Value(level);
  static Insertable<Grade> custom({
    Expression<int>? id,
    Expression<int>? level,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
    });
  }

  GradesCompanion copyWith({Value<int>? id, Value<int>? level}) {
    return GradesCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesCompanion(')
          ..write('id: $id, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }
}

class $StreamsTable extends Streams with TableInfo<$StreamsTable, Stream> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, slug];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streams';
  @override
  VerificationContext validateIntegrity(Insertable<Stream> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stream map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stream(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
    );
  }

  @override
  $StreamsTable createAlias(String alias) {
    return $StreamsTable(attachedDatabase, alias);
  }
}

class Stream extends DataClass implements Insertable<Stream> {
  final int id;
  final String slug;
  const Stream({required this.id, required this.slug});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    return map;
  }

  StreamsCompanion toCompanion(bool nullToAbsent) {
    return StreamsCompanion(
      id: Value(id),
      slug: Value(slug),
    );
  }

  factory Stream.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stream(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
    };
  }

  Stream copyWith({int? id, String? slug}) => Stream(
        id: id ?? this.id,
        slug: slug ?? this.slug,
      );
  Stream copyWithCompanion(StreamsCompanion data) {
    return Stream(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stream(')
          ..write('id: $id, ')
          ..write('slug: $slug')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stream && other.id == this.id && other.slug == this.slug);
}

class StreamsCompanion extends UpdateCompanion<Stream> {
  final Value<int> id;
  final Value<String> slug;
  const StreamsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
  });
  StreamsCompanion.insert({
    this.id = const Value.absent(),
    required String slug,
  }) : slug = Value(slug);
  static Insertable<Stream> custom({
    Expression<int>? id,
    Expression<String>? slug,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
    });
  }

  StreamsCompanion copyWith({Value<int>? id, Value<String>? slug}) {
    return StreamsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _streamIdMeta =
      const VerificationMeta('streamId');
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
      'stream_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES streams (id)'));
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, streamId, slug, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<Subject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stream_id')) {
      context.handle(_streamIdMeta,
          streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta));
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {streamId, slug},
      ];
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      streamId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stream_id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final int id;
  final int streamId;
  final String slug;
  final String title;
  const Subject(
      {required this.id,
      required this.streamId,
      required this.slug,
      required this.title});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stream_id'] = Variable<int>(streamId);
    map['slug'] = Variable<String>(slug);
    map['title'] = Variable<String>(title);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      streamId: Value(streamId),
      slug: Value(slug),
      title: Value(title),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<int>(json['id']),
      streamId: serializer.fromJson<int>(json['streamId']),
      slug: serializer.fromJson<String>(json['slug']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'streamId': serializer.toJson<int>(streamId),
      'slug': serializer.toJson<String>(slug),
      'title': serializer.toJson<String>(title),
    };
  }

  Subject copyWith({int? id, int? streamId, String? slug, String? title}) =>
      Subject(
        id: id ?? this.id,
        streamId: streamId ?? this.streamId,
        slug: slug ?? this.slug,
        title: title ?? this.title,
      );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      slug: data.slug.present ? data.slug.value : this.slug,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('streamId: $streamId, ')
          ..write('slug: $slug, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, streamId, slug, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.streamId == this.streamId &&
          other.slug == this.slug &&
          other.title == this.title);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<int> streamId;
  final Value<String> slug;
  final Value<String> title;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.streamId = const Value.absent(),
    this.slug = const Value.absent(),
    this.title = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    required int streamId,
    required String slug,
    required String title,
  })  : streamId = Value(streamId),
        slug = Value(slug),
        title = Value(title);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<int>? streamId,
    Expression<String>? slug,
    Expression<String>? title,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (streamId != null) 'stream_id': streamId,
      if (slug != null) 'slug': slug,
      if (title != null) 'title': title,
    });
  }

  SubjectsCompanion copyWith(
      {Value<int>? id,
      Value<int>? streamId,
      Value<String>? slug,
      Value<String>? title}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('streamId: $streamId, ')
          ..write('slug: $slug, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }
}

class $ContentPacksTable extends ContentPacks
    with TableInfo<$ContentPacksTable, ContentPack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _packKeyMeta =
      const VerificationMeta('packKey');
  @override
  late final GeneratedColumn<String> packKey = GeneratedColumn<String>(
      'pack_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  static const VerificationMeta _packVersionMeta =
      const VerificationMeta('packVersion');
  @override
  late final GeneratedColumn<String> packVersion = GeneratedColumn<String>(
      'pack_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<String> schemaVersion = GeneratedColumn<String>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<String> generatedAt = GeneratedColumn<String>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minimumAppVersionMeta =
      const VerificationMeta('minimumAppVersion');
  @override
  late final GeneratedColumn<String> minimumAppVersion =
      GeneratedColumn<String>('minimum_app_version', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<String> importedAt = GeneratedColumn<String>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        packKey,
        subjectId,
        packVersion,
        schemaVersion,
        generatedAt,
        checksum,
        minimumAppVersion,
        importedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_packs';
  @override
  VerificationContext validateIntegrity(Insertable<ContentPack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pack_key')) {
      context.handle(_packKeyMeta,
          packKey.isAcceptableOrUnknown(data['pack_key']!, _packKeyMeta));
    } else if (isInserting) {
      context.missing(_packKeyMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('pack_version')) {
      context.handle(
          _packVersionMeta,
          packVersion.isAcceptableOrUnknown(
              data['pack_version']!, _packVersionMeta));
    } else if (isInserting) {
      context.missing(_packVersionMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('minimum_app_version')) {
      context.handle(
          _minimumAppVersionMeta,
          minimumAppVersion.isAcceptableOrUnknown(
              data['minimum_app_version']!, _minimumAppVersionMeta));
    } else if (isInserting) {
      context.missing(_minimumAppVersionMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {packKey, packVersion},
      ];
  @override
  ContentPack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPack(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      packKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_key'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subject_id'])!,
      packVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_version'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schema_version'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}generated_at'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum'])!,
      minimumAppVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}minimum_app_version'])!,
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imported_at'])!,
    );
  }

  @override
  $ContentPacksTable createAlias(String alias) {
    return $ContentPacksTable(attachedDatabase, alias);
  }
}

class ContentPack extends DataClass implements Insertable<ContentPack> {
  final String id;
  final String packKey;
  final int subjectId;
  final String packVersion;
  final String schemaVersion;
  final String generatedAt;
  final String checksum;
  final String minimumAppVersion;
  final String importedAt;
  const ContentPack(
      {required this.id,
      required this.packKey,
      required this.subjectId,
      required this.packVersion,
      required this.schemaVersion,
      required this.generatedAt,
      required this.checksum,
      required this.minimumAppVersion,
      required this.importedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pack_key'] = Variable<String>(packKey);
    map['subject_id'] = Variable<int>(subjectId);
    map['pack_version'] = Variable<String>(packVersion);
    map['schema_version'] = Variable<String>(schemaVersion);
    map['generated_at'] = Variable<String>(generatedAt);
    map['checksum'] = Variable<String>(checksum);
    map['minimum_app_version'] = Variable<String>(minimumAppVersion);
    map['imported_at'] = Variable<String>(importedAt);
    return map;
  }

  ContentPacksCompanion toCompanion(bool nullToAbsent) {
    return ContentPacksCompanion(
      id: Value(id),
      packKey: Value(packKey),
      subjectId: Value(subjectId),
      packVersion: Value(packVersion),
      schemaVersion: Value(schemaVersion),
      generatedAt: Value(generatedAt),
      checksum: Value(checksum),
      minimumAppVersion: Value(minimumAppVersion),
      importedAt: Value(importedAt),
    );
  }

  factory ContentPack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPack(
      id: serializer.fromJson<String>(json['id']),
      packKey: serializer.fromJson<String>(json['packKey']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      packVersion: serializer.fromJson<String>(json['packVersion']),
      schemaVersion: serializer.fromJson<String>(json['schemaVersion']),
      generatedAt: serializer.fromJson<String>(json['generatedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      minimumAppVersion: serializer.fromJson<String>(json['minimumAppVersion']),
      importedAt: serializer.fromJson<String>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packKey': serializer.toJson<String>(packKey),
      'subjectId': serializer.toJson<int>(subjectId),
      'packVersion': serializer.toJson<String>(packVersion),
      'schemaVersion': serializer.toJson<String>(schemaVersion),
      'generatedAt': serializer.toJson<String>(generatedAt),
      'checksum': serializer.toJson<String>(checksum),
      'minimumAppVersion': serializer.toJson<String>(minimumAppVersion),
      'importedAt': serializer.toJson<String>(importedAt),
    };
  }

  ContentPack copyWith(
          {String? id,
          String? packKey,
          int? subjectId,
          String? packVersion,
          String? schemaVersion,
          String? generatedAt,
          String? checksum,
          String? minimumAppVersion,
          String? importedAt}) =>
      ContentPack(
        id: id ?? this.id,
        packKey: packKey ?? this.packKey,
        subjectId: subjectId ?? this.subjectId,
        packVersion: packVersion ?? this.packVersion,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        generatedAt: generatedAt ?? this.generatedAt,
        checksum: checksum ?? this.checksum,
        minimumAppVersion: minimumAppVersion ?? this.minimumAppVersion,
        importedAt: importedAt ?? this.importedAt,
      );
  ContentPack copyWithCompanion(ContentPacksCompanion data) {
    return ContentPack(
      id: data.id.present ? data.id.value : this.id,
      packKey: data.packKey.present ? data.packKey.value : this.packKey,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      packVersion:
          data.packVersion.present ? data.packVersion.value : this.packVersion,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      minimumAppVersion: data.minimumAppVersion.present
          ? data.minimumAppVersion.value
          : this.minimumAppVersion,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPack(')
          ..write('id: $id, ')
          ..write('packKey: $packKey, ')
          ..write('subjectId: $subjectId, ')
          ..write('packVersion: $packVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('checksum: $checksum, ')
          ..write('minimumAppVersion: $minimumAppVersion, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, packKey, subjectId, packVersion,
      schemaVersion, generatedAt, checksum, minimumAppVersion, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPack &&
          other.id == this.id &&
          other.packKey == this.packKey &&
          other.subjectId == this.subjectId &&
          other.packVersion == this.packVersion &&
          other.schemaVersion == this.schemaVersion &&
          other.generatedAt == this.generatedAt &&
          other.checksum == this.checksum &&
          other.minimumAppVersion == this.minimumAppVersion &&
          other.importedAt == this.importedAt);
}

class ContentPacksCompanion extends UpdateCompanion<ContentPack> {
  final Value<String> id;
  final Value<String> packKey;
  final Value<int> subjectId;
  final Value<String> packVersion;
  final Value<String> schemaVersion;
  final Value<String> generatedAt;
  final Value<String> checksum;
  final Value<String> minimumAppVersion;
  final Value<String> importedAt;
  final Value<int> rowid;
  const ContentPacksCompanion({
    this.id = const Value.absent(),
    this.packKey = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.minimumAppVersion = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPacksCompanion.insert({
    required String id,
    required String packKey,
    required int subjectId,
    required String packVersion,
    required String schemaVersion,
    required String generatedAt,
    required String checksum,
    required String minimumAppVersion,
    required String importedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        packKey = Value(packKey),
        subjectId = Value(subjectId),
        packVersion = Value(packVersion),
        schemaVersion = Value(schemaVersion),
        generatedAt = Value(generatedAt),
        checksum = Value(checksum),
        minimumAppVersion = Value(minimumAppVersion),
        importedAt = Value(importedAt);
  static Insertable<ContentPack> custom({
    Expression<String>? id,
    Expression<String>? packKey,
    Expression<int>? subjectId,
    Expression<String>? packVersion,
    Expression<String>? schemaVersion,
    Expression<String>? generatedAt,
    Expression<String>? checksum,
    Expression<String>? minimumAppVersion,
    Expression<String>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packKey != null) 'pack_key': packKey,
      if (subjectId != null) 'subject_id': subjectId,
      if (packVersion != null) 'pack_version': packVersion,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (checksum != null) 'checksum': checksum,
      if (minimumAppVersion != null) 'minimum_app_version': minimumAppVersion,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPacksCompanion copyWith(
      {Value<String>? id,
      Value<String>? packKey,
      Value<int>? subjectId,
      Value<String>? packVersion,
      Value<String>? schemaVersion,
      Value<String>? generatedAt,
      Value<String>? checksum,
      Value<String>? minimumAppVersion,
      Value<String>? importedAt,
      Value<int>? rowid}) {
    return ContentPacksCompanion(
      id: id ?? this.id,
      packKey: packKey ?? this.packKey,
      subjectId: subjectId ?? this.subjectId,
      packVersion: packVersion ?? this.packVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      checksum: checksum ?? this.checksum,
      minimumAppVersion: minimumAppVersion ?? this.minimumAppVersion,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packKey.present) {
      map['pack_key'] = Variable<String>(packKey.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (packVersion.present) {
      map['pack_version'] = Variable<String>(packVersion.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<String>(schemaVersion.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<String>(generatedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (minimumAppVersion.present) {
      map['minimum_app_version'] = Variable<String>(minimumAppVersion.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<String>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPacksCompanion(')
          ..write('id: $id, ')
          ..write('packKey: $packKey, ')
          ..write('subjectId: $subjectId, ')
          ..write('packVersion: $packVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('checksum: $checksum, ')
          ..write('minimumAppVersion: $minimumAppVersion, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  static const VerificationMeta _gradeIdMeta =
      const VerificationMeta('gradeId');
  @override
  late final GeneratedColumn<int> gradeId = GeneratedColumn<int>(
      'grade_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES grades (id)'));
  static const VerificationMeta _sourcePackIdMeta =
      const VerificationMeta('sourcePackId');
  @override
  late final GeneratedColumn<String> sourcePackId = GeneratedColumn<String>(
      'source_pack_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES content_packs (id)'));
  static const VerificationMeta _packLocalIdMeta =
      const VerificationMeta('packLocalId');
  @override
  late final GeneratedColumn<String> packLocalId = GeneratedColumn<String>(
      'pack_local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, subjectId, gradeId, sourcePackId, packLocalId, title, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(Insertable<Chapter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('grade_id')) {
      context.handle(_gradeIdMeta,
          gradeId.isAcceptableOrUnknown(data['grade_id']!, _gradeIdMeta));
    } else if (isInserting) {
      context.missing(_gradeIdMeta);
    }
    if (data.containsKey('source_pack_id')) {
      context.handle(
          _sourcePackIdMeta,
          sourcePackId.isAcceptableOrUnknown(
              data['source_pack_id']!, _sourcePackIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePackIdMeta);
    }
    if (data.containsKey('pack_local_id')) {
      context.handle(
          _packLocalIdMeta,
          packLocalId.isAcceptableOrUnknown(
              data['pack_local_id']!, _packLocalIdMeta));
    } else if (isInserting) {
      context.missing(_packLocalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subject_id'])!,
      gradeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grade_id'])!,
      sourcePackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_pack_id'])!,
      packLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_local_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final int id;
  final int subjectId;
  final int gradeId;
  final String sourcePackId;
  final String packLocalId;
  final String title;
  final int orderIndex;
  const Chapter(
      {required this.id,
      required this.subjectId,
      required this.gradeId,
      required this.sourcePackId,
      required this.packLocalId,
      required this.title,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    map['grade_id'] = Variable<int>(gradeId);
    map['source_pack_id'] = Variable<String>(sourcePackId);
    map['pack_local_id'] = Variable<String>(packLocalId);
    map['title'] = Variable<String>(title);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      gradeId: Value(gradeId),
      sourcePackId: Value(sourcePackId),
      packLocalId: Value(packLocalId),
      title: Value(title),
      orderIndex: Value(orderIndex),
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      gradeId: serializer.fromJson<int>(json['gradeId']),
      sourcePackId: serializer.fromJson<String>(json['sourcePackId']),
      packLocalId: serializer.fromJson<String>(json['packLocalId']),
      title: serializer.fromJson<String>(json['title']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'gradeId': serializer.toJson<int>(gradeId),
      'sourcePackId': serializer.toJson<String>(sourcePackId),
      'packLocalId': serializer.toJson<String>(packLocalId),
      'title': serializer.toJson<String>(title),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  Chapter copyWith(
          {int? id,
          int? subjectId,
          int? gradeId,
          String? sourcePackId,
          String? packLocalId,
          String? title,
          int? orderIndex}) =>
      Chapter(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        gradeId: gradeId ?? this.gradeId,
        sourcePackId: sourcePackId ?? this.sourcePackId,
        packLocalId: packLocalId ?? this.packLocalId,
        title: title ?? this.title,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      gradeId: data.gradeId.present ? data.gradeId.value : this.gradeId,
      sourcePackId: data.sourcePackId.present
          ? data.sourcePackId.value
          : this.sourcePackId,
      packLocalId:
          data.packLocalId.present ? data.packLocalId.value : this.packLocalId,
      title: data.title.present ? data.title.value : this.title,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('gradeId: $gradeId, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, subjectId, gradeId, sourcePackId, packLocalId, title, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.gradeId == this.gradeId &&
          other.sourcePackId == this.sourcePackId &&
          other.packLocalId == this.packLocalId &&
          other.title == this.title &&
          other.orderIndex == this.orderIndex);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<int> gradeId;
  final Value<String> sourcePackId;
  final Value<String> packLocalId;
  final Value<String> title;
  final Value<int> orderIndex;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.gradeId = const Value.absent(),
    this.sourcePackId = const Value.absent(),
    this.packLocalId = const Value.absent(),
    this.title = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    required int gradeId,
    required String sourcePackId,
    required String packLocalId,
    required String title,
    required int orderIndex,
  })  : subjectId = Value(subjectId),
        gradeId = Value(gradeId),
        sourcePackId = Value(sourcePackId),
        packLocalId = Value(packLocalId),
        title = Value(title),
        orderIndex = Value(orderIndex);
  static Insertable<Chapter> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? gradeId,
    Expression<String>? sourcePackId,
    Expression<String>? packLocalId,
    Expression<String>? title,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (gradeId != null) 'grade_id': gradeId,
      if (sourcePackId != null) 'source_pack_id': sourcePackId,
      if (packLocalId != null) 'pack_local_id': packLocalId,
      if (title != null) 'title': title,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  ChaptersCompanion copyWith(
      {Value<int>? id,
      Value<int>? subjectId,
      Value<int>? gradeId,
      Value<String>? sourcePackId,
      Value<String>? packLocalId,
      Value<String>? title,
      Value<int>? orderIndex}) {
    return ChaptersCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      gradeId: gradeId ?? this.gradeId,
      sourcePackId: sourcePackId ?? this.sourcePackId,
      packLocalId: packLocalId ?? this.packLocalId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (gradeId.present) {
      map['grade_id'] = Variable<int>(gradeId.value);
    }
    if (sourcePackId.present) {
      map['source_pack_id'] = Variable<String>(sourcePackId.value);
    }
    if (packLocalId.present) {
      map['pack_local_id'] = Variable<String>(packLocalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('gradeId: $gradeId, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $TopicsTable extends Topics with TableInfo<$TopicsTable, Topic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES chapters (id)'));
  static const VerificationMeta _sourcePackIdMeta =
      const VerificationMeta('sourcePackId');
  @override
  late final GeneratedColumn<String> sourcePackId = GeneratedColumn<String>(
      'source_pack_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES content_packs (id)'));
  static const VerificationMeta _packLocalIdMeta =
      const VerificationMeta('packLocalId');
  @override
  late final GeneratedColumn<String> packLocalId = GeneratedColumn<String>(
      'pack_local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, chapterId, sourcePackId, packLocalId, title, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topics';
  @override
  VerificationContext validateIntegrity(Insertable<Topic> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('source_pack_id')) {
      context.handle(
          _sourcePackIdMeta,
          sourcePackId.isAcceptableOrUnknown(
              data['source_pack_id']!, _sourcePackIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePackIdMeta);
    }
    if (data.containsKey('pack_local_id')) {
      context.handle(
          _packLocalIdMeta,
          packLocalId.isAcceptableOrUnknown(
              data['pack_local_id']!, _packLocalIdMeta));
    } else if (isInserting) {
      context.missing(_packLocalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
  @override
  Topic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Topic(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_id'])!,
      sourcePackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_pack_id'])!,
      packLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_local_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $TopicsTable createAlias(String alias) {
    return $TopicsTable(attachedDatabase, alias);
  }
}

class Topic extends DataClass implements Insertable<Topic> {
  final int id;
  final int chapterId;
  final String sourcePackId;
  final String packLocalId;
  final String title;
  final int orderIndex;
  const Topic(
      {required this.id,
      required this.chapterId,
      required this.sourcePackId,
      required this.packLocalId,
      required this.title,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['source_pack_id'] = Variable<String>(sourcePackId);
    map['pack_local_id'] = Variable<String>(packLocalId);
    map['title'] = Variable<String>(title);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  TopicsCompanion toCompanion(bool nullToAbsent) {
    return TopicsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      sourcePackId: Value(sourcePackId),
      packLocalId: Value(packLocalId),
      title: Value(title),
      orderIndex: Value(orderIndex),
    );
  }

  factory Topic.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Topic(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      sourcePackId: serializer.fromJson<String>(json['sourcePackId']),
      packLocalId: serializer.fromJson<String>(json['packLocalId']),
      title: serializer.fromJson<String>(json['title']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'sourcePackId': serializer.toJson<String>(sourcePackId),
      'packLocalId': serializer.toJson<String>(packLocalId),
      'title': serializer.toJson<String>(title),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  Topic copyWith(
          {int? id,
          int? chapterId,
          String? sourcePackId,
          String? packLocalId,
          String? title,
          int? orderIndex}) =>
      Topic(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        sourcePackId: sourcePackId ?? this.sourcePackId,
        packLocalId: packLocalId ?? this.packLocalId,
        title: title ?? this.title,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  Topic copyWithCompanion(TopicsCompanion data) {
    return Topic(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      sourcePackId: data.sourcePackId.present
          ? data.sourcePackId.value
          : this.sourcePackId,
      packLocalId:
          data.packLocalId.present ? data.packLocalId.value : this.packLocalId,
      title: data.title.present ? data.title.value : this.title,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Topic(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, chapterId, sourcePackId, packLocalId, title, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Topic &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.sourcePackId == this.sourcePackId &&
          other.packLocalId == this.packLocalId &&
          other.title == this.title &&
          other.orderIndex == this.orderIndex);
}

class TopicsCompanion extends UpdateCompanion<Topic> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<String> sourcePackId;
  final Value<String> packLocalId;
  final Value<String> title;
  final Value<int> orderIndex;
  const TopicsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.sourcePackId = const Value.absent(),
    this.packLocalId = const Value.absent(),
    this.title = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  TopicsCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required String sourcePackId,
    required String packLocalId,
    required String title,
    required int orderIndex,
  })  : chapterId = Value(chapterId),
        sourcePackId = Value(sourcePackId),
        packLocalId = Value(packLocalId),
        title = Value(title),
        orderIndex = Value(orderIndex);
  static Insertable<Topic> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<String>? sourcePackId,
    Expression<String>? packLocalId,
    Expression<String>? title,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (sourcePackId != null) 'source_pack_id': sourcePackId,
      if (packLocalId != null) 'pack_local_id': packLocalId,
      if (title != null) 'title': title,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  TopicsCompanion copyWith(
      {Value<int>? id,
      Value<int>? chapterId,
      Value<String>? sourcePackId,
      Value<String>? packLocalId,
      Value<String>? title,
      Value<int>? orderIndex}) {
    return TopicsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      sourcePackId: sourcePackId ?? this.sourcePackId,
      packLocalId: packLocalId ?? this.packLocalId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (sourcePackId.present) {
      map['source_pack_id'] = Variable<String>(sourcePackId.value);
    }
    if (packLocalId.present) {
      map['pack_local_id'] = Variable<String>(packLocalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourcePackIdMeta =
      const VerificationMeta('sourcePackId');
  @override
  late final GeneratedColumn<String> sourcePackId = GeneratedColumn<String>(
      'source_pack_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES content_packs (id)'));
  static const VerificationMeta _packLocalIdMeta =
      const VerificationMeta('packLocalId');
  @override
  late final GeneratedColumn<String> packLocalId = GeneratedColumn<String>(
      'pack_local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
      'prompt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _choicesJsonMeta =
      const VerificationMeta('choicesJson');
  @override
  late final GeneratedColumn<String> choicesJson = GeneratedColumn<String>(
      'choices_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctChoiceIndexMeta =
      const VerificationMeta('correctChoiceIndex');
  @override
  late final GeneratedColumn<int> correctChoiceIndex = GeneratedColumn<int>(
      'correct_choice_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _textbookReferenceMeta =
      const VerificationMeta('textbookReference');
  @override
  late final GeneratedColumn<String> textbookReference =
      GeneratedColumn<String>('textbook_reference', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _examYearEcMeta =
      const VerificationMeta('examYearEc');
  @override
  late final GeneratedColumn<int> examYearEc = GeneratedColumn<int>(
      'exam_year_ec', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageReferenceMeta =
      const VerificationMeta('imageReference');
  @override
  late final GeneratedColumn<String> imageReference = GeneratedColumn<String>(
      'image_reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _graphReferenceMeta =
      const VerificationMeta('graphReference');
  @override
  late final GeneratedColumn<String> graphReference = GeneratedColumn<String>(
      'graph_reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagramReferenceMeta =
      const VerificationMeta('diagramReference');
  @override
  late final GeneratedColumn<String> diagramReference = GeneratedColumn<String>(
      'diagram_reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tableReferenceMeta =
      const VerificationMeta('tableReference');
  @override
  late final GeneratedColumn<String> tableReference = GeneratedColumn<String>(
      'table_reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourcePackId,
        packLocalId,
        prompt,
        choicesJson,
        correctChoiceIndex,
        explanation,
        textbookReference,
        examYearEc,
        imageReference,
        graphReference,
        diagramReference,
        tableReference
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(Insertable<Question> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_pack_id')) {
      context.handle(
          _sourcePackIdMeta,
          sourcePackId.isAcceptableOrUnknown(
              data['source_pack_id']!, _sourcePackIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePackIdMeta);
    }
    if (data.containsKey('pack_local_id')) {
      context.handle(
          _packLocalIdMeta,
          packLocalId.isAcceptableOrUnknown(
              data['pack_local_id']!, _packLocalIdMeta));
    } else if (isInserting) {
      context.missing(_packLocalIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(_promptMeta,
          prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta));
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('choices_json')) {
      context.handle(
          _choicesJsonMeta,
          choicesJson.isAcceptableOrUnknown(
              data['choices_json']!, _choicesJsonMeta));
    } else if (isInserting) {
      context.missing(_choicesJsonMeta);
    }
    if (data.containsKey('correct_choice_index')) {
      context.handle(
          _correctChoiceIndexMeta,
          correctChoiceIndex.isAcceptableOrUnknown(
              data['correct_choice_index']!, _correctChoiceIndexMeta));
    } else if (isInserting) {
      context.missing(_correctChoiceIndexMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    if (data.containsKey('textbook_reference')) {
      context.handle(
          _textbookReferenceMeta,
          textbookReference.isAcceptableOrUnknown(
              data['textbook_reference']!, _textbookReferenceMeta));
    }
    if (data.containsKey('exam_year_ec')) {
      context.handle(
          _examYearEcMeta,
          examYearEc.isAcceptableOrUnknown(
              data['exam_year_ec']!, _examYearEcMeta));
    }
    if (data.containsKey('image_reference')) {
      context.handle(
          _imageReferenceMeta,
          imageReference.isAcceptableOrUnknown(
              data['image_reference']!, _imageReferenceMeta));
    }
    if (data.containsKey('graph_reference')) {
      context.handle(
          _graphReferenceMeta,
          graphReference.isAcceptableOrUnknown(
              data['graph_reference']!, _graphReferenceMeta));
    }
    if (data.containsKey('diagram_reference')) {
      context.handle(
          _diagramReferenceMeta,
          diagramReference.isAcceptableOrUnknown(
              data['diagram_reference']!, _diagramReferenceMeta));
    }
    if (data.containsKey('table_reference')) {
      context.handle(
          _tableReferenceMeta,
          tableReference.isAcceptableOrUnknown(
              data['table_reference']!, _tableReferenceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sourcePackId, packLocalId},
      ];
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourcePackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_pack_id'])!,
      packLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_local_id'])!,
      prompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt'])!,
      choicesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}choices_json'])!,
      correctChoiceIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}correct_choice_index'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
      textbookReference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}textbook_reference']),
      examYearEc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exam_year_ec']),
      imageReference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_reference']),
      graphReference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}graph_reference']),
      diagramReference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}diagram_reference']),
      tableReference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_reference']),
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  final int id;
  final String sourcePackId;
  final String packLocalId;
  final String prompt;
  final String choicesJson;
  final int correctChoiceIndex;
  final String? explanation;
  final String? textbookReference;
  final int? examYearEc;
  final String? imageReference;
  final String? graphReference;
  final String? diagramReference;
  final String? tableReference;
  const Question(
      {required this.id,
      required this.sourcePackId,
      required this.packLocalId,
      required this.prompt,
      required this.choicesJson,
      required this.correctChoiceIndex,
      this.explanation,
      this.textbookReference,
      this.examYearEc,
      this.imageReference,
      this.graphReference,
      this.diagramReference,
      this.tableReference});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_pack_id'] = Variable<String>(sourcePackId);
    map['pack_local_id'] = Variable<String>(packLocalId);
    map['prompt'] = Variable<String>(prompt);
    map['choices_json'] = Variable<String>(choicesJson);
    map['correct_choice_index'] = Variable<int>(correctChoiceIndex);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || textbookReference != null) {
      map['textbook_reference'] = Variable<String>(textbookReference);
    }
    if (!nullToAbsent || examYearEc != null) {
      map['exam_year_ec'] = Variable<int>(examYearEc);
    }
    if (!nullToAbsent || imageReference != null) {
      map['image_reference'] = Variable<String>(imageReference);
    }
    if (!nullToAbsent || graphReference != null) {
      map['graph_reference'] = Variable<String>(graphReference);
    }
    if (!nullToAbsent || diagramReference != null) {
      map['diagram_reference'] = Variable<String>(diagramReference);
    }
    if (!nullToAbsent || tableReference != null) {
      map['table_reference'] = Variable<String>(tableReference);
    }
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      sourcePackId: Value(sourcePackId),
      packLocalId: Value(packLocalId),
      prompt: Value(prompt),
      choicesJson: Value(choicesJson),
      correctChoiceIndex: Value(correctChoiceIndex),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      textbookReference: textbookReference == null && nullToAbsent
          ? const Value.absent()
          : Value(textbookReference),
      examYearEc: examYearEc == null && nullToAbsent
          ? const Value.absent()
          : Value(examYearEc),
      imageReference: imageReference == null && nullToAbsent
          ? const Value.absent()
          : Value(imageReference),
      graphReference: graphReference == null && nullToAbsent
          ? const Value.absent()
          : Value(graphReference),
      diagramReference: diagramReference == null && nullToAbsent
          ? const Value.absent()
          : Value(diagramReference),
      tableReference: tableReference == null && nullToAbsent
          ? const Value.absent()
          : Value(tableReference),
    );
  }

  factory Question.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<int>(json['id']),
      sourcePackId: serializer.fromJson<String>(json['sourcePackId']),
      packLocalId: serializer.fromJson<String>(json['packLocalId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      choicesJson: serializer.fromJson<String>(json['choicesJson']),
      correctChoiceIndex: serializer.fromJson<int>(json['correctChoiceIndex']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      textbookReference:
          serializer.fromJson<String?>(json['textbookReference']),
      examYearEc: serializer.fromJson<int?>(json['examYearEc']),
      imageReference: serializer.fromJson<String?>(json['imageReference']),
      graphReference: serializer.fromJson<String?>(json['graphReference']),
      diagramReference: serializer.fromJson<String?>(json['diagramReference']),
      tableReference: serializer.fromJson<String?>(json['tableReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePackId': serializer.toJson<String>(sourcePackId),
      'packLocalId': serializer.toJson<String>(packLocalId),
      'prompt': serializer.toJson<String>(prompt),
      'choicesJson': serializer.toJson<String>(choicesJson),
      'correctChoiceIndex': serializer.toJson<int>(correctChoiceIndex),
      'explanation': serializer.toJson<String?>(explanation),
      'textbookReference': serializer.toJson<String?>(textbookReference),
      'examYearEc': serializer.toJson<int?>(examYearEc),
      'imageReference': serializer.toJson<String?>(imageReference),
      'graphReference': serializer.toJson<String?>(graphReference),
      'diagramReference': serializer.toJson<String?>(diagramReference),
      'tableReference': serializer.toJson<String?>(tableReference),
    };
  }

  Question copyWith(
          {int? id,
          String? sourcePackId,
          String? packLocalId,
          String? prompt,
          String? choicesJson,
          int? correctChoiceIndex,
          Value<String?> explanation = const Value.absent(),
          Value<String?> textbookReference = const Value.absent(),
          Value<int?> examYearEc = const Value.absent(),
          Value<String?> imageReference = const Value.absent(),
          Value<String?> graphReference = const Value.absent(),
          Value<String?> diagramReference = const Value.absent(),
          Value<String?> tableReference = const Value.absent()}) =>
      Question(
        id: id ?? this.id,
        sourcePackId: sourcePackId ?? this.sourcePackId,
        packLocalId: packLocalId ?? this.packLocalId,
        prompt: prompt ?? this.prompt,
        choicesJson: choicesJson ?? this.choicesJson,
        correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
        explanation: explanation.present ? explanation.value : this.explanation,
        textbookReference: textbookReference.present
            ? textbookReference.value
            : this.textbookReference,
        examYearEc: examYearEc.present ? examYearEc.value : this.examYearEc,
        imageReference:
            imageReference.present ? imageReference.value : this.imageReference,
        graphReference:
            graphReference.present ? graphReference.value : this.graphReference,
        diagramReference: diagramReference.present
            ? diagramReference.value
            : this.diagramReference,
        tableReference:
            tableReference.present ? tableReference.value : this.tableReference,
      );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      sourcePackId: data.sourcePackId.present
          ? data.sourcePackId.value
          : this.sourcePackId,
      packLocalId:
          data.packLocalId.present ? data.packLocalId.value : this.packLocalId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      choicesJson:
          data.choicesJson.present ? data.choicesJson.value : this.choicesJson,
      correctChoiceIndex: data.correctChoiceIndex.present
          ? data.correctChoiceIndex.value
          : this.correctChoiceIndex,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      textbookReference: data.textbookReference.present
          ? data.textbookReference.value
          : this.textbookReference,
      examYearEc:
          data.examYearEc.present ? data.examYearEc.value : this.examYearEc,
      imageReference: data.imageReference.present
          ? data.imageReference.value
          : this.imageReference,
      graphReference: data.graphReference.present
          ? data.graphReference.value
          : this.graphReference,
      diagramReference: data.diagramReference.present
          ? data.diagramReference.value
          : this.diagramReference,
      tableReference: data.tableReference.present
          ? data.tableReference.value
          : this.tableReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('prompt: $prompt, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('correctChoiceIndex: $correctChoiceIndex, ')
          ..write('explanation: $explanation, ')
          ..write('textbookReference: $textbookReference, ')
          ..write('examYearEc: $examYearEc, ')
          ..write('imageReference: $imageReference, ')
          ..write('graphReference: $graphReference, ')
          ..write('diagramReference: $diagramReference, ')
          ..write('tableReference: $tableReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sourcePackId,
      packLocalId,
      prompt,
      choicesJson,
      correctChoiceIndex,
      explanation,
      textbookReference,
      examYearEc,
      imageReference,
      graphReference,
      diagramReference,
      tableReference);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.sourcePackId == this.sourcePackId &&
          other.packLocalId == this.packLocalId &&
          other.prompt == this.prompt &&
          other.choicesJson == this.choicesJson &&
          other.correctChoiceIndex == this.correctChoiceIndex &&
          other.explanation == this.explanation &&
          other.textbookReference == this.textbookReference &&
          other.examYearEc == this.examYearEc &&
          other.imageReference == this.imageReference &&
          other.graphReference == this.graphReference &&
          other.diagramReference == this.diagramReference &&
          other.tableReference == this.tableReference);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<int> id;
  final Value<String> sourcePackId;
  final Value<String> packLocalId;
  final Value<String> prompt;
  final Value<String> choicesJson;
  final Value<int> correctChoiceIndex;
  final Value<String?> explanation;
  final Value<String?> textbookReference;
  final Value<int?> examYearEc;
  final Value<String?> imageReference;
  final Value<String?> graphReference;
  final Value<String?> diagramReference;
  final Value<String?> tableReference;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.sourcePackId = const Value.absent(),
    this.packLocalId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.choicesJson = const Value.absent(),
    this.correctChoiceIndex = const Value.absent(),
    this.explanation = const Value.absent(),
    this.textbookReference = const Value.absent(),
    this.examYearEc = const Value.absent(),
    this.imageReference = const Value.absent(),
    this.graphReference = const Value.absent(),
    this.diagramReference = const Value.absent(),
    this.tableReference = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePackId,
    required String packLocalId,
    required String prompt,
    required String choicesJson,
    required int correctChoiceIndex,
    this.explanation = const Value.absent(),
    this.textbookReference = const Value.absent(),
    this.examYearEc = const Value.absent(),
    this.imageReference = const Value.absent(),
    this.graphReference = const Value.absent(),
    this.diagramReference = const Value.absent(),
    this.tableReference = const Value.absent(),
  })  : sourcePackId = Value(sourcePackId),
        packLocalId = Value(packLocalId),
        prompt = Value(prompt),
        choicesJson = Value(choicesJson),
        correctChoiceIndex = Value(correctChoiceIndex);
  static Insertable<Question> custom({
    Expression<int>? id,
    Expression<String>? sourcePackId,
    Expression<String>? packLocalId,
    Expression<String>? prompt,
    Expression<String>? choicesJson,
    Expression<int>? correctChoiceIndex,
    Expression<String>? explanation,
    Expression<String>? textbookReference,
    Expression<int>? examYearEc,
    Expression<String>? imageReference,
    Expression<String>? graphReference,
    Expression<String>? diagramReference,
    Expression<String>? tableReference,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePackId != null) 'source_pack_id': sourcePackId,
      if (packLocalId != null) 'pack_local_id': packLocalId,
      if (prompt != null) 'prompt': prompt,
      if (choicesJson != null) 'choices_json': choicesJson,
      if (correctChoiceIndex != null)
        'correct_choice_index': correctChoiceIndex,
      if (explanation != null) 'explanation': explanation,
      if (textbookReference != null) 'textbook_reference': textbookReference,
      if (examYearEc != null) 'exam_year_ec': examYearEc,
      if (imageReference != null) 'image_reference': imageReference,
      if (graphReference != null) 'graph_reference': graphReference,
      if (diagramReference != null) 'diagram_reference': diagramReference,
      if (tableReference != null) 'table_reference': tableReference,
    });
  }

  QuestionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? sourcePackId,
      Value<String>? packLocalId,
      Value<String>? prompt,
      Value<String>? choicesJson,
      Value<int>? correctChoiceIndex,
      Value<String?>? explanation,
      Value<String?>? textbookReference,
      Value<int?>? examYearEc,
      Value<String?>? imageReference,
      Value<String?>? graphReference,
      Value<String?>? diagramReference,
      Value<String?>? tableReference}) {
    return QuestionsCompanion(
      id: id ?? this.id,
      sourcePackId: sourcePackId ?? this.sourcePackId,
      packLocalId: packLocalId ?? this.packLocalId,
      prompt: prompt ?? this.prompt,
      choicesJson: choicesJson ?? this.choicesJson,
      correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
      explanation: explanation ?? this.explanation,
      textbookReference: textbookReference ?? this.textbookReference,
      examYearEc: examYearEc ?? this.examYearEc,
      imageReference: imageReference ?? this.imageReference,
      graphReference: graphReference ?? this.graphReference,
      diagramReference: diagramReference ?? this.diagramReference,
      tableReference: tableReference ?? this.tableReference,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePackId.present) {
      map['source_pack_id'] = Variable<String>(sourcePackId.value);
    }
    if (packLocalId.present) {
      map['pack_local_id'] = Variable<String>(packLocalId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (choicesJson.present) {
      map['choices_json'] = Variable<String>(choicesJson.value);
    }
    if (correctChoiceIndex.present) {
      map['correct_choice_index'] = Variable<int>(correctChoiceIndex.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (textbookReference.present) {
      map['textbook_reference'] = Variable<String>(textbookReference.value);
    }
    if (examYearEc.present) {
      map['exam_year_ec'] = Variable<int>(examYearEc.value);
    }
    if (imageReference.present) {
      map['image_reference'] = Variable<String>(imageReference.value);
    }
    if (graphReference.present) {
      map['graph_reference'] = Variable<String>(graphReference.value);
    }
    if (diagramReference.present) {
      map['diagram_reference'] = Variable<String>(diagramReference.value);
    }
    if (tableReference.present) {
      map['table_reference'] = Variable<String>(tableReference.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('sourcePackId: $sourcePackId, ')
          ..write('packLocalId: $packLocalId, ')
          ..write('prompt: $prompt, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('correctChoiceIndex: $correctChoiceIndex, ')
          ..write('explanation: $explanation, ')
          ..write('textbookReference: $textbookReference, ')
          ..write('examYearEc: $examYearEc, ')
          ..write('imageReference: $imageReference, ')
          ..write('graphReference: $graphReference, ')
          ..write('diagramReference: $diagramReference, ')
          ..write('tableReference: $tableReference')
          ..write(')'))
        .toString();
  }
}

class $QuestionTopicsTable extends QuestionTopics
    with TableInfo<$QuestionTopicsTable, QuestionTopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
      'question_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES questions (id)'));
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
      'topic_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES topics (id)'));
  @override
  List<GeneratedColumn> get $columns => [questionId, topicId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_topics';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionTopic> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId, topicId};
  @override
  QuestionTopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionTopic(
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_id'])!,
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}topic_id'])!,
    );
  }

  @override
  $QuestionTopicsTable createAlias(String alias) {
    return $QuestionTopicsTable(attachedDatabase, alias);
  }
}

class QuestionTopic extends DataClass implements Insertable<QuestionTopic> {
  final int questionId;
  final int topicId;
  const QuestionTopic({required this.questionId, required this.topicId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<int>(questionId);
    map['topic_id'] = Variable<int>(topicId);
    return map;
  }

  QuestionTopicsCompanion toCompanion(bool nullToAbsent) {
    return QuestionTopicsCompanion(
      questionId: Value(questionId),
      topicId: Value(topicId),
    );
  }

  factory QuestionTopic.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionTopic(
      questionId: serializer.fromJson<int>(json['questionId']),
      topicId: serializer.fromJson<int>(json['topicId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<int>(questionId),
      'topicId': serializer.toJson<int>(topicId),
    };
  }

  QuestionTopic copyWith({int? questionId, int? topicId}) => QuestionTopic(
        questionId: questionId ?? this.questionId,
        topicId: topicId ?? this.topicId,
      );
  QuestionTopic copyWithCompanion(QuestionTopicsCompanion data) {
    return QuestionTopic(
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTopic(')
          ..write('questionId: $questionId, ')
          ..write('topicId: $topicId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questionId, topicId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionTopic &&
          other.questionId == this.questionId &&
          other.topicId == this.topicId);
}

class QuestionTopicsCompanion extends UpdateCompanion<QuestionTopic> {
  final Value<int> questionId;
  final Value<int> topicId;
  final Value<int> rowid;
  const QuestionTopicsCompanion({
    this.questionId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionTopicsCompanion.insert({
    required int questionId,
    required int topicId,
    this.rowid = const Value.absent(),
  })  : questionId = Value(questionId),
        topicId = Value(topicId);
  static Insertable<QuestionTopic> custom({
    Expression<int>? questionId,
    Expression<int>? topicId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (topicId != null) 'topic_id': topicId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionTopicsCompanion copyWith(
      {Value<int>? questionId, Value<int>? topicId, Value<int>? rowid}) {
    return QuestionTopicsCompanion(
      questionId: questionId ?? this.questionId,
      topicId: topicId ?? this.topicId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTopicsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('topicId: $topicId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GradesTable grades = $GradesTable(this);
  late final $StreamsTable streams = $StreamsTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $ContentPacksTable contentPacks = $ContentPacksTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $TopicsTable topics = $TopicsTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuestionTopicsTable questionTopics = $QuestionTopicsTable(this);
  late final Index idxChaptersSubjectGrade = Index('idx_chapters_subject_grade',
      'CREATE INDEX idx_chapters_subject_grade ON chapters (subject_id, grade_id)');
  late final Index idxTopicsChapterId = Index('idx_topics_chapter_id',
      'CREATE INDEX idx_topics_chapter_id ON topics (chapter_id)');
  late final Index idxQuestionsSourcePack = Index('idx_questions_source_pack',
      'CREATE INDEX idx_questions_source_pack ON questions (source_pack_id)');
  late final Index idxQuestionTopicsTopic = Index('idx_question_topics_topic',
      'CREATE INDEX idx_question_topics_topic ON question_topics (topic_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        grades,
        streams,
        subjects,
        contentPacks,
        chapters,
        topics,
        questions,
        questionTopics,
        idxChaptersSubjectGrade,
        idxTopicsChapterId,
        idxQuestionsSourcePack,
        idxQuestionTopicsTopic
      ];
}

typedef $$GradesTableCreateCompanionBuilder = GradesCompanion Function({
  Value<int> id,
  required int level,
});
typedef $$GradesTableUpdateCompanionBuilder = GradesCompanion Function({
  Value<int> id,
  Value<int> level,
});

final class $$GradesTableReferences
    extends BaseReferences<_$AppDatabase, $GradesTable, Grade> {
  $$GradesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.chapters,
          aliasName: 'grades__id__chapters__grade_id');

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager($_db, $_db.chapters)
        .filter((f) => f.gradeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GradesTableFilterComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  Expression<bool> chaptersRefs(
      Expression<bool> Function($$ChaptersTableFilterComposer f) f) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.gradeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableFilterComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GradesTableOrderingComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));
}

class $$GradesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  Expression<T> chaptersRefs<T extends Object>(
      Expression<T> Function($$ChaptersTableAnnotationComposer a) f) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.gradeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableAnnotationComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GradesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GradesTable,
    Grade,
    $$GradesTableFilterComposer,
    $$GradesTableOrderingComposer,
    $$GradesTableAnnotationComposer,
    $$GradesTableCreateCompanionBuilder,
    $$GradesTableUpdateCompanionBuilder,
    (Grade, $$GradesTableReferences),
    Grade,
    PrefetchHooks Function({bool chaptersRefs})> {
  $$GradesTableTableManager(_$AppDatabase db, $GradesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> level = const Value.absent(),
          }) =>
              GradesCompanion(
            id: id,
            level: level,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int level,
          }) =>
              GradesCompanion.insert(
            id: id,
            level: level,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GradesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({chaptersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chaptersRefs) db.chapters],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chaptersRefs)
                    await $_getPrefetchedData<Grade, $GradesTable, Chapter>(
                        currentTable: table,
                        referencedTable:
                            $$GradesTableReferences._chaptersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GradesTableReferences(db, table, p0).chaptersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.gradeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GradesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GradesTable,
    Grade,
    $$GradesTableFilterComposer,
    $$GradesTableOrderingComposer,
    $$GradesTableAnnotationComposer,
    $$GradesTableCreateCompanionBuilder,
    $$GradesTableUpdateCompanionBuilder,
    (Grade, $$GradesTableReferences),
    Grade,
    PrefetchHooks Function({bool chaptersRefs})>;
typedef $$StreamsTableCreateCompanionBuilder = StreamsCompanion Function({
  Value<int> id,
  required String slug,
});
typedef $$StreamsTableUpdateCompanionBuilder = StreamsCompanion Function({
  Value<int> id,
  Value<String> slug,
});

final class $$StreamsTableReferences
    extends BaseReferences<_$AppDatabase, $StreamsTable, Stream> {
  $$StreamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubjectsTable, List<Subject>> _subjectsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.subjects,
          aliasName: 'streams__id__subjects__stream_id');

  $$SubjectsTableProcessedTableManager get subjectsRefs {
    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.streamId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StreamsTableFilterComposer
    extends Composer<_$AppDatabase, $StreamsTable> {
  $$StreamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  Expression<bool> subjectsRefs(
      Expression<bool> Function($$SubjectsTableFilterComposer f) f) {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.streamId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StreamsTableOrderingComposer
    extends Composer<_$AppDatabase, $StreamsTable> {
  $$StreamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));
}

class $$StreamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreamsTable> {
  $$StreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  Expression<T> subjectsRefs<T extends Object>(
      Expression<T> Function($$SubjectsTableAnnotationComposer a) f) {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.streamId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StreamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StreamsTable,
    Stream,
    $$StreamsTableFilterComposer,
    $$StreamsTableOrderingComposer,
    $$StreamsTableAnnotationComposer,
    $$StreamsTableCreateCompanionBuilder,
    $$StreamsTableUpdateCompanionBuilder,
    (Stream, $$StreamsTableReferences),
    Stream,
    PrefetchHooks Function({bool subjectsRefs})> {
  $$StreamsTableTableManager(_$AppDatabase db, $StreamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> slug = const Value.absent(),
          }) =>
              StreamsCompanion(
            id: id,
            slug: slug,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String slug,
          }) =>
              StreamsCompanion.insert(
            id: id,
            slug: slug,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$StreamsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({subjectsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (subjectsRefs) db.subjects],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (subjectsRefs)
                    await $_getPrefetchedData<Stream, $StreamsTable, Subject>(
                        currentTable: table,
                        referencedTable:
                            $$StreamsTableReferences._subjectsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StreamsTableReferences(db, table, p0)
                                .subjectsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.streamId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StreamsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StreamsTable,
    Stream,
    $$StreamsTableFilterComposer,
    $$StreamsTableOrderingComposer,
    $$StreamsTableAnnotationComposer,
    $$StreamsTableCreateCompanionBuilder,
    $$StreamsTableUpdateCompanionBuilder,
    (Stream, $$StreamsTableReferences),
    Stream,
    PrefetchHooks Function({bool subjectsRefs})>;
typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  required int streamId,
  required String slug,
  required String title,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  Value<int> streamId,
  Value<String> slug,
  Value<String> title,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StreamsTable _streamIdTable(_$AppDatabase db) =>
      db.streams.createAlias('subjects__stream_id__streams__id');

  $$StreamsTableProcessedTableManager get streamId {
    final $_column = $_itemColumn<int>('stream_id')!;

    final manager = $$StreamsTableTableManager($_db, $_db.streams)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_streamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ContentPacksTable, List<ContentPack>>
      _contentPacksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.contentPacks,
              aliasName: 'subjects__id__content_packs__subject_id');

  $$ContentPacksTableProcessedTableManager get contentPacksRefs {
    final manager = $$ContentPacksTableTableManager($_db, $_db.contentPacks)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contentPacksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.chapters,
          aliasName: 'subjects__id__chapters__subject_id');

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager($_db, $_db.chapters)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  $$StreamsTableFilterComposer get streamId {
    final $$StreamsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.streamId,
        referencedTable: $db.streams,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StreamsTableFilterComposer(
              $db: $db,
              $table: $db.streams,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> contentPacksRefs(
      Expression<bool> Function($$ContentPacksTableFilterComposer f) f) {
    final $$ContentPacksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableFilterComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> chaptersRefs(
      Expression<bool> Function($$ChaptersTableFilterComposer f) f) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableFilterComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  $$StreamsTableOrderingComposer get streamId {
    final $$StreamsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.streamId,
        referencedTable: $db.streams,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StreamsTableOrderingComposer(
              $db: $db,
              $table: $db.streams,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  $$StreamsTableAnnotationComposer get streamId {
    final $$StreamsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.streamId,
        referencedTable: $db.streams,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StreamsTableAnnotationComposer(
              $db: $db,
              $table: $db.streams,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> contentPacksRefs<T extends Object>(
      Expression<T> Function($$ContentPacksTableAnnotationComposer a) f) {
    final $$ContentPacksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableAnnotationComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
      Expression<T> Function($$ChaptersTableAnnotationComposer a) f) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableAnnotationComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function(
        {bool streamId, bool contentPacksRefs, bool chaptersRefs})> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> streamId = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String> title = const Value.absent(),
          }) =>
              SubjectsCompanion(
            id: id,
            streamId: streamId,
            slug: slug,
            title: title,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int streamId,
            required String slug,
            required String title,
          }) =>
              SubjectsCompanion.insert(
            id: id,
            streamId: streamId,
            slug: slug,
            title: title,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SubjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {streamId = false,
              contentPacksRefs = false,
              chaptersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contentPacksRefs) db.contentPacks,
                if (chaptersRefs) db.chapters
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (streamId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.streamId,
                    referencedTable:
                        $$SubjectsTableReferences._streamIdTable(db),
                    referencedColumn:
                        $$SubjectsTableReferences._streamIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contentPacksRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable,
                            ContentPack>(
                        currentTable: table,
                        referencedTable: $$SubjectsTableReferences
                            ._contentPacksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .contentPacksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items),
                  if (chaptersRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable, Chapter>(
                        currentTable: table,
                        referencedTable:
                            $$SubjectsTableReferences._chaptersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .chaptersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function(
        {bool streamId, bool contentPacksRefs, bool chaptersRefs})>;
typedef $$ContentPacksTableCreateCompanionBuilder = ContentPacksCompanion
    Function({
  required String id,
  required String packKey,
  required int subjectId,
  required String packVersion,
  required String schemaVersion,
  required String generatedAt,
  required String checksum,
  required String minimumAppVersion,
  required String importedAt,
  Value<int> rowid,
});
typedef $$ContentPacksTableUpdateCompanionBuilder = ContentPacksCompanion
    Function({
  Value<String> id,
  Value<String> packKey,
  Value<int> subjectId,
  Value<String> packVersion,
  Value<String> schemaVersion,
  Value<String> generatedAt,
  Value<String> checksum,
  Value<String> minimumAppVersion,
  Value<String> importedAt,
  Value<int> rowid,
});

final class $$ContentPacksTableReferences
    extends BaseReferences<_$AppDatabase, $ContentPacksTable, ContentPack> {
  $$ContentPacksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('content_packs__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.chapters,
          aliasName: 'content_packs__id__chapters__source_pack_id');

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager($_db, $_db.chapters).filter(
        (f) => f.sourcePackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TopicsTable, List<Topic>> _topicsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.topics,
          aliasName: 'content_packs__id__topics__source_pack_id');

  $$TopicsTableProcessedTableManager get topicsRefs {
    final manager = $$TopicsTableTableManager($_db, $_db.topics).filter(
        (f) => f.sourcePackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_topicsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$QuestionsTable, List<Question>>
      _questionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.questions,
              aliasName: 'content_packs__id__questions__source_pack_id');

  $$QuestionsTableProcessedTableManager get questionsRefs {
    final manager = $$QuestionsTableTableManager($_db, $_db.questions).filter(
        (f) => f.sourcePackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ContentPacksTableFilterComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packKey => $composableBuilder(
      column: $table.packKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packVersion => $composableBuilder(
      column: $table.packVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get minimumAppVersion => $composableBuilder(
      column: $table.minimumAppVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> chaptersRefs(
      Expression<bool> Function($$ChaptersTableFilterComposer f) f) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableFilterComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> topicsRefs(
      Expression<bool> Function($$TopicsTableFilterComposer f) f) {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableFilterComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> questionsRefs(
      Expression<bool> Function($$QuestionsTableFilterComposer f) f) {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableFilterComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContentPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packKey => $composableBuilder(
      column: $table.packKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packVersion => $composableBuilder(
      column: $table.packVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get minimumAppVersion => $composableBuilder(
      column: $table.minimumAppVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContentPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => column);

  GeneratedColumn<String> get packVersion => $composableBuilder(
      column: $table.packVersion, builder: (column) => column);

  GeneratedColumn<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);

  GeneratedColumn<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get minimumAppVersion => $composableBuilder(
      column: $table.minimumAppVersion, builder: (column) => column);

  GeneratedColumn<String> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> chaptersRefs<T extends Object>(
      Expression<T> Function($$ChaptersTableAnnotationComposer a) f) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableAnnotationComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> topicsRefs<T extends Object>(
      Expression<T> Function($$TopicsTableAnnotationComposer a) f) {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableAnnotationComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> questionsRefs<T extends Object>(
      Expression<T> Function($$QuestionsTableAnnotationComposer a) f) {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.sourcePackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContentPacksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContentPacksTable,
    ContentPack,
    $$ContentPacksTableFilterComposer,
    $$ContentPacksTableOrderingComposer,
    $$ContentPacksTableAnnotationComposer,
    $$ContentPacksTableCreateCompanionBuilder,
    $$ContentPacksTableUpdateCompanionBuilder,
    (ContentPack, $$ContentPacksTableReferences),
    ContentPack,
    PrefetchHooks Function(
        {bool subjectId,
        bool chaptersRefs,
        bool topicsRefs,
        bool questionsRefs})> {
  $$ContentPacksTableTableManager(_$AppDatabase db, $ContentPacksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> packKey = const Value.absent(),
            Value<int> subjectId = const Value.absent(),
            Value<String> packVersion = const Value.absent(),
            Value<String> schemaVersion = const Value.absent(),
            Value<String> generatedAt = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<String> minimumAppVersion = const Value.absent(),
            Value<String> importedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContentPacksCompanion(
            id: id,
            packKey: packKey,
            subjectId: subjectId,
            packVersion: packVersion,
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            checksum: checksum,
            minimumAppVersion: minimumAppVersion,
            importedAt: importedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String packKey,
            required int subjectId,
            required String packVersion,
            required String schemaVersion,
            required String generatedAt,
            required String checksum,
            required String minimumAppVersion,
            required String importedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ContentPacksCompanion.insert(
            id: id,
            packKey: packKey,
            subjectId: subjectId,
            packVersion: packVersion,
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            checksum: checksum,
            minimumAppVersion: minimumAppVersion,
            importedAt: importedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ContentPacksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false,
              chaptersRefs = false,
              topicsRefs = false,
              questionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (chaptersRefs) db.chapters,
                if (topicsRefs) db.topics,
                if (questionsRefs) db.questions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$ContentPacksTableReferences._subjectIdTable(db),
                    referencedColumn:
                        $$ContentPacksTableReferences._subjectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chaptersRefs)
                    await $_getPrefetchedData<ContentPack, $ContentPacksTable,
                            Chapter>(
                        currentTable: table,
                        referencedTable: $$ContentPacksTableReferences
                            ._chaptersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContentPacksTableReferences(db, table, p0)
                                .chaptersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePackId == item.id),
                        typedResults: items),
                  if (topicsRefs)
                    await $_getPrefetchedData<ContentPack, $ContentPacksTable,
                            Topic>(
                        currentTable: table,
                        referencedTable:
                            $$ContentPacksTableReferences._topicsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContentPacksTableReferences(db, table, p0)
                                .topicsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePackId == item.id),
                        typedResults: items),
                  if (questionsRefs)
                    await $_getPrefetchedData<ContentPack, $ContentPacksTable,
                            Question>(
                        currentTable: table,
                        referencedTable: $$ContentPacksTableReferences
                            ._questionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContentPacksTableReferences(db, table, p0)
                                .questionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePackId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ContentPacksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContentPacksTable,
    ContentPack,
    $$ContentPacksTableFilterComposer,
    $$ContentPacksTableOrderingComposer,
    $$ContentPacksTableAnnotationComposer,
    $$ContentPacksTableCreateCompanionBuilder,
    $$ContentPacksTableUpdateCompanionBuilder,
    (ContentPack, $$ContentPacksTableReferences),
    ContentPack,
    PrefetchHooks Function(
        {bool subjectId,
        bool chaptersRefs,
        bool topicsRefs,
        bool questionsRefs})>;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  required int subjectId,
  required int gradeId,
  required String sourcePackId,
  required String packLocalId,
  required String title,
  required int orderIndex,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  Value<int> subjectId,
  Value<int> gradeId,
  Value<String> sourcePackId,
  Value<String> packLocalId,
  Value<String> title,
  Value<int> orderIndex,
});

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('chapters__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $GradesTable _gradeIdTable(_$AppDatabase db) =>
      db.grades.createAlias('chapters__grade_id__grades__id');

  $$GradesTableProcessedTableManager get gradeId {
    final $_column = $_itemColumn<int>('grade_id')!;

    final manager = $$GradesTableTableManager($_db, $_db.grades)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gradeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContentPacksTable _sourcePackIdTable(_$AppDatabase db) =>
      db.contentPacks
          .createAlias('chapters__source_pack_id__content_packs__id');

  $$ContentPacksTableProcessedTableManager get sourcePackId {
    final $_column = $_itemColumn<String>('source_pack_id')!;

    final manager = $$ContentPacksTableTableManager($_db, $_db.contentPacks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourcePackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TopicsTable, List<Topic>> _topicsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.topics,
          aliasName: 'chapters__id__topics__chapter_id');

  $$TopicsTableProcessedTableManager get topicsRefs {
    final manager = $$TopicsTableTableManager($_db, $_db.topics)
        .filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_topicsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GradesTableFilterComposer get gradeId {
    final $$GradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gradeId,
        referencedTable: $db.grades,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GradesTableFilterComposer(
              $db: $db,
              $table: $db.grades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableFilterComposer get sourcePackId {
    final $$ContentPacksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableFilterComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> topicsRefs(
      Expression<bool> Function($$TopicsTableFilterComposer f) f) {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.chapterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableFilterComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GradesTableOrderingComposer get gradeId {
    final $$GradesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gradeId,
        referencedTable: $db.grades,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GradesTableOrderingComposer(
              $db: $db,
              $table: $db.grades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableOrderingComposer get sourcePackId {
    final $$ContentPacksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableOrderingComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GradesTableAnnotationComposer get gradeId {
    final $$GradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.gradeId,
        referencedTable: $db.grades,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GradesTableAnnotationComposer(
              $db: $db,
              $table: $db.grades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableAnnotationComposer get sourcePackId {
    final $$ContentPacksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableAnnotationComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> topicsRefs<T extends Object>(
      Expression<T> Function($$TopicsTableAnnotationComposer a) f) {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.chapterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableAnnotationComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChaptersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, $$ChaptersTableReferences),
    Chapter,
    PrefetchHooks Function(
        {bool subjectId, bool gradeId, bool sourcePackId, bool topicsRefs})> {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> subjectId = const Value.absent(),
            Value<int> gradeId = const Value.absent(),
            Value<String> sourcePackId = const Value.absent(),
            Value<String> packLocalId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              ChaptersCompanion(
            id: id,
            subjectId: subjectId,
            gradeId: gradeId,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            title: title,
            orderIndex: orderIndex,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int subjectId,
            required int gradeId,
            required String sourcePackId,
            required String packLocalId,
            required String title,
            required int orderIndex,
          }) =>
              ChaptersCompanion.insert(
            id: id,
            subjectId: subjectId,
            gradeId: gradeId,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            title: title,
            orderIndex: orderIndex,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ChaptersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false,
              gradeId = false,
              sourcePackId = false,
              topicsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (topicsRefs) db.topics],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$ChaptersTableReferences._subjectIdTable(db),
                    referencedColumn:
                        $$ChaptersTableReferences._subjectIdTable(db).id,
                  ) as T;
                }
                if (gradeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.gradeId,
                    referencedTable:
                        $$ChaptersTableReferences._gradeIdTable(db),
                    referencedColumn:
                        $$ChaptersTableReferences._gradeIdTable(db).id,
                  ) as T;
                }
                if (sourcePackId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePackId,
                    referencedTable:
                        $$ChaptersTableReferences._sourcePackIdTable(db),
                    referencedColumn:
                        $$ChaptersTableReferences._sourcePackIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (topicsRefs)
                    await $_getPrefetchedData<Chapter, $ChaptersTable, Topic>(
                        currentTable: table,
                        referencedTable:
                            $$ChaptersTableReferences._topicsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChaptersTableReferences(db, table, p0).topicsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.chapterId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChaptersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, $$ChaptersTableReferences),
    Chapter,
    PrefetchHooks Function(
        {bool subjectId, bool gradeId, bool sourcePackId, bool topicsRefs})>;
typedef $$TopicsTableCreateCompanionBuilder = TopicsCompanion Function({
  Value<int> id,
  required int chapterId,
  required String sourcePackId,
  required String packLocalId,
  required String title,
  required int orderIndex,
});
typedef $$TopicsTableUpdateCompanionBuilder = TopicsCompanion Function({
  Value<int> id,
  Value<int> chapterId,
  Value<String> sourcePackId,
  Value<String> packLocalId,
  Value<String> title,
  Value<int> orderIndex,
});

final class $$TopicsTableReferences
    extends BaseReferences<_$AppDatabase, $TopicsTable, Topic> {
  $$TopicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.chapters.createAlias('topics__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager($_db, $_db.chapters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContentPacksTable _sourcePackIdTable(_$AppDatabase db) =>
      db.contentPacks.createAlias('topics__source_pack_id__content_packs__id');

  $$ContentPacksTableProcessedTableManager get sourcePackId {
    final $_column = $_itemColumn<String>('source_pack_id')!;

    final manager = $$ContentPacksTableTableManager($_db, $_db.contentPacks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourcePackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$QuestionTopicsTable, List<QuestionTopic>>
      _questionTopicsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.questionTopics,
              aliasName: 'topics__id__question_topics__topic_id');

  $$QuestionTopicsTableProcessedTableManager get questionTopicsRefs {
    final manager = $$QuestionTopicsTableTableManager($_db, $_db.questionTopics)
        .filter((f) => f.topicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionTopicsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TopicsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicsTable> {
  $$TopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableFilterComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableFilterComposer get sourcePackId {
    final $$ContentPacksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableFilterComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> questionTopicsRefs(
      Expression<bool> Function($$QuestionTopicsTableFilterComposer f) f) {
    final $$QuestionTopicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questionTopics,
        getReferencedColumn: (t) => t.topicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionTopicsTableFilterComposer(
              $db: $db,
              $table: $db.questionTopics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicsTable> {
  $$TopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableOrderingComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableOrderingComposer get sourcePackId {
    final $$ContentPacksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableOrderingComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicsTable> {
  $$TopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableAnnotationComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContentPacksTableAnnotationComposer get sourcePackId {
    final $$ContentPacksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableAnnotationComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> questionTopicsRefs<T extends Object>(
      Expression<T> Function($$QuestionTopicsTableAnnotationComposer a) f) {
    final $$QuestionTopicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questionTopics,
        getReferencedColumn: (t) => t.topicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionTopicsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionTopics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TopicsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TopicsTable,
    Topic,
    $$TopicsTableFilterComposer,
    $$TopicsTableOrderingComposer,
    $$TopicsTableAnnotationComposer,
    $$TopicsTableCreateCompanionBuilder,
    $$TopicsTableUpdateCompanionBuilder,
    (Topic, $$TopicsTableReferences),
    Topic,
    PrefetchHooks Function(
        {bool chapterId, bool sourcePackId, bool questionTopicsRefs})> {
  $$TopicsTableTableManager(_$AppDatabase db, $TopicsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> chapterId = const Value.absent(),
            Value<String> sourcePackId = const Value.absent(),
            Value<String> packLocalId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              TopicsCompanion(
            id: id,
            chapterId: chapterId,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            title: title,
            orderIndex: orderIndex,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int chapterId,
            required String sourcePackId,
            required String packLocalId,
            required String title,
            required int orderIndex,
          }) =>
              TopicsCompanion.insert(
            id: id,
            chapterId: chapterId,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            title: title,
            orderIndex: orderIndex,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TopicsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {chapterId = false,
              sourcePackId = false,
              questionTopicsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (questionTopicsRefs) db.questionTopics
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (chapterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.chapterId,
                    referencedTable:
                        $$TopicsTableReferences._chapterIdTable(db),
                    referencedColumn:
                        $$TopicsTableReferences._chapterIdTable(db).id,
                  ) as T;
                }
                if (sourcePackId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePackId,
                    referencedTable:
                        $$TopicsTableReferences._sourcePackIdTable(db),
                    referencedColumn:
                        $$TopicsTableReferences._sourcePackIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (questionTopicsRefs)
                    await $_getPrefetchedData<Topic, $TopicsTable,
                            QuestionTopic>(
                        currentTable: table,
                        referencedTable: $$TopicsTableReferences
                            ._questionTopicsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TopicsTableReferences(db, table, p0)
                                .questionTopicsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.topicId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TopicsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TopicsTable,
    Topic,
    $$TopicsTableFilterComposer,
    $$TopicsTableOrderingComposer,
    $$TopicsTableAnnotationComposer,
    $$TopicsTableCreateCompanionBuilder,
    $$TopicsTableUpdateCompanionBuilder,
    (Topic, $$TopicsTableReferences),
    Topic,
    PrefetchHooks Function(
        {bool chapterId, bool sourcePackId, bool questionTopicsRefs})>;
typedef $$QuestionsTableCreateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  required String sourcePackId,
  required String packLocalId,
  required String prompt,
  required String choicesJson,
  required int correctChoiceIndex,
  Value<String?> explanation,
  Value<String?> textbookReference,
  Value<int?> examYearEc,
  Value<String?> imageReference,
  Value<String?> graphReference,
  Value<String?> diagramReference,
  Value<String?> tableReference,
});
typedef $$QuestionsTableUpdateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  Value<String> sourcePackId,
  Value<String> packLocalId,
  Value<String> prompt,
  Value<String> choicesJson,
  Value<int> correctChoiceIndex,
  Value<String?> explanation,
  Value<String?> textbookReference,
  Value<int?> examYearEc,
  Value<String?> imageReference,
  Value<String?> graphReference,
  Value<String?> diagramReference,
  Value<String?> tableReference,
});

final class $$QuestionsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionsTable, Question> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContentPacksTable _sourcePackIdTable(_$AppDatabase db) =>
      db.contentPacks
          .createAlias('questions__source_pack_id__content_packs__id');

  $$ContentPacksTableProcessedTableManager get sourcePackId {
    final $_column = $_itemColumn<String>('source_pack_id')!;

    final manager = $$ContentPacksTableTableManager($_db, $_db.contentPacks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourcePackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$QuestionTopicsTable, List<QuestionTopic>>
      _questionTopicsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.questionTopics,
              aliasName: 'questions__id__question_topics__question_id');

  $$QuestionTopicsTableProcessedTableManager get questionTopicsRefs {
    final manager = $$QuestionTopicsTableTableManager($_db, $_db.questionTopics)
        .filter((f) => f.questionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionTopicsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctChoiceIndex => $composableBuilder(
      column: $table.correctChoiceIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textbookReference => $composableBuilder(
      column: $table.textbookReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get examYearEc => $composableBuilder(
      column: $table.examYearEc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageReference => $composableBuilder(
      column: $table.imageReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get graphReference => $composableBuilder(
      column: $table.graphReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagramReference => $composableBuilder(
      column: $table.diagramReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tableReference => $composableBuilder(
      column: $table.tableReference,
      builder: (column) => ColumnFilters(column));

  $$ContentPacksTableFilterComposer get sourcePackId {
    final $$ContentPacksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableFilterComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> questionTopicsRefs(
      Expression<bool> Function($$QuestionTopicsTableFilterComposer f) f) {
    final $$QuestionTopicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questionTopics,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionTopicsTableFilterComposer(
              $db: $db,
              $table: $db.questionTopics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctChoiceIndex => $composableBuilder(
      column: $table.correctChoiceIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textbookReference => $composableBuilder(
      column: $table.textbookReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get examYearEc => $composableBuilder(
      column: $table.examYearEc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageReference => $composableBuilder(
      column: $table.imageReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get graphReference => $composableBuilder(
      column: $table.graphReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagramReference => $composableBuilder(
      column: $table.diagramReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tableReference => $composableBuilder(
      column: $table.tableReference,
      builder: (column) => ColumnOrderings(column));

  $$ContentPacksTableOrderingComposer get sourcePackId {
    final $$ContentPacksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableOrderingComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packLocalId => $composableBuilder(
      column: $table.packLocalId, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson, builder: (column) => column);

  GeneratedColumn<int> get correctChoiceIndex => $composableBuilder(
      column: $table.correctChoiceIndex, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<String> get textbookReference => $composableBuilder(
      column: $table.textbookReference, builder: (column) => column);

  GeneratedColumn<int> get examYearEc => $composableBuilder(
      column: $table.examYearEc, builder: (column) => column);

  GeneratedColumn<String> get imageReference => $composableBuilder(
      column: $table.imageReference, builder: (column) => column);

  GeneratedColumn<String> get graphReference => $composableBuilder(
      column: $table.graphReference, builder: (column) => column);

  GeneratedColumn<String> get diagramReference => $composableBuilder(
      column: $table.diagramReference, builder: (column) => column);

  GeneratedColumn<String> get tableReference => $composableBuilder(
      column: $table.tableReference, builder: (column) => column);

  $$ContentPacksTableAnnotationComposer get sourcePackId {
    final $$ContentPacksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePackId,
        referencedTable: $db.contentPacks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentPacksTableAnnotationComposer(
              $db: $db,
              $table: $db.contentPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> questionTopicsRefs<T extends Object>(
      Expression<T> Function($$QuestionTopicsTableAnnotationComposer a) f) {
    final $$QuestionTopicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.questionTopics,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionTopicsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionTopics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, $$QuestionsTableReferences),
    Question,
    PrefetchHooks Function({bool sourcePackId, bool questionTopicsRefs})> {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sourcePackId = const Value.absent(),
            Value<String> packLocalId = const Value.absent(),
            Value<String> prompt = const Value.absent(),
            Value<String> choicesJson = const Value.absent(),
            Value<int> correctChoiceIndex = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<String?> textbookReference = const Value.absent(),
            Value<int?> examYearEc = const Value.absent(),
            Value<String?> imageReference = const Value.absent(),
            Value<String?> graphReference = const Value.absent(),
            Value<String?> diagramReference = const Value.absent(),
            Value<String?> tableReference = const Value.absent(),
          }) =>
              QuestionsCompanion(
            id: id,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            prompt: prompt,
            choicesJson: choicesJson,
            correctChoiceIndex: correctChoiceIndex,
            explanation: explanation,
            textbookReference: textbookReference,
            examYearEc: examYearEc,
            imageReference: imageReference,
            graphReference: graphReference,
            diagramReference: diagramReference,
            tableReference: tableReference,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sourcePackId,
            required String packLocalId,
            required String prompt,
            required String choicesJson,
            required int correctChoiceIndex,
            Value<String?> explanation = const Value.absent(),
            Value<String?> textbookReference = const Value.absent(),
            Value<int?> examYearEc = const Value.absent(),
            Value<String?> imageReference = const Value.absent(),
            Value<String?> graphReference = const Value.absent(),
            Value<String?> diagramReference = const Value.absent(),
            Value<String?> tableReference = const Value.absent(),
          }) =>
              QuestionsCompanion.insert(
            id: id,
            sourcePackId: sourcePackId,
            packLocalId: packLocalId,
            prompt: prompt,
            choicesJson: choicesJson,
            correctChoiceIndex: correctChoiceIndex,
            explanation: explanation,
            textbookReference: textbookReference,
            examYearEc: examYearEc,
            imageReference: imageReference,
            graphReference: graphReference,
            diagramReference: diagramReference,
            tableReference: tableReference,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sourcePackId = false, questionTopicsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (questionTopicsRefs) db.questionTopics
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourcePackId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePackId,
                    referencedTable:
                        $$QuestionsTableReferences._sourcePackIdTable(db),
                    referencedColumn:
                        $$QuestionsTableReferences._sourcePackIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (questionTopicsRefs)
                    await $_getPrefetchedData<Question, $QuestionsTable,
                            QuestionTopic>(
                        currentTable: table,
                        referencedTable: $$QuestionsTableReferences
                            ._questionTopicsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionsTableReferences(db, table, p0)
                                .questionTopicsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuestionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, $$QuestionsTableReferences),
    Question,
    PrefetchHooks Function({bool sourcePackId, bool questionTopicsRefs})>;
typedef $$QuestionTopicsTableCreateCompanionBuilder = QuestionTopicsCompanion
    Function({
  required int questionId,
  required int topicId,
  Value<int> rowid,
});
typedef $$QuestionTopicsTableUpdateCompanionBuilder = QuestionTopicsCompanion
    Function({
  Value<int> questionId,
  Value<int> topicId,
  Value<int> rowid,
});

final class $$QuestionTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionTopicsTable, QuestionTopic> {
  $$QuestionTopicsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuestionsTable _questionIdTable(_$AppDatabase db) =>
      db.questions.createAlias('question_topics__question_id__questions__id');

  $$QuestionsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<int>('question_id')!;

    final manager = $$QuestionsTableTableManager($_db, $_db.questions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TopicsTable _topicIdTable(_$AppDatabase db) =>
      db.topics.createAlias('question_topics__topic_id__topics__id');

  $$TopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<int>('topic_id')!;

    final manager = $$TopicsTableTableManager($_db, $_db.topics)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$QuestionTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionTopicsTable> {
  $$QuestionTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableFilterComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TopicsTableFilterComposer get topicId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.topicId,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableFilterComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuestionTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionTopicsTable> {
  $$QuestionTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableOrderingComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TopicsTableOrderingComposer get topicId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.topicId,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableOrderingComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuestionTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionTopicsTable> {
  $$QuestionTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TopicsTableAnnotationComposer get topicId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.topicId,
        referencedTable: $db.topics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TopicsTableAnnotationComposer(
              $db: $db,
              $table: $db.topics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuestionTopicsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionTopicsTable,
    QuestionTopic,
    $$QuestionTopicsTableFilterComposer,
    $$QuestionTopicsTableOrderingComposer,
    $$QuestionTopicsTableAnnotationComposer,
    $$QuestionTopicsTableCreateCompanionBuilder,
    $$QuestionTopicsTableUpdateCompanionBuilder,
    (QuestionTopic, $$QuestionTopicsTableReferences),
    QuestionTopic,
    PrefetchHooks Function({bool questionId, bool topicId})> {
  $$QuestionTopicsTableTableManager(
      _$AppDatabase db, $QuestionTopicsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> questionId = const Value.absent(),
            Value<int> topicId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionTopicsCompanion(
            questionId: questionId,
            topicId: topicId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int questionId,
            required int topicId,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionTopicsCompanion.insert(
            questionId: questionId,
            topicId: topicId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionTopicsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({questionId = false, topicId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (questionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionId,
                    referencedTable:
                        $$QuestionTopicsTableReferences._questionIdTable(db),
                    referencedColumn:
                        $$QuestionTopicsTableReferences._questionIdTable(db).id,
                  ) as T;
                }
                if (topicId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.topicId,
                    referencedTable:
                        $$QuestionTopicsTableReferences._topicIdTable(db),
                    referencedColumn:
                        $$QuestionTopicsTableReferences._topicIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$QuestionTopicsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionTopicsTable,
    QuestionTopic,
    $$QuestionTopicsTableFilterComposer,
    $$QuestionTopicsTableOrderingComposer,
    $$QuestionTopicsTableAnnotationComposer,
    $$QuestionTopicsTableCreateCompanionBuilder,
    $$QuestionTopicsTableUpdateCompanionBuilder,
    (QuestionTopic, $$QuestionTopicsTableReferences),
    QuestionTopic,
    PrefetchHooks Function({bool questionId, bool topicId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GradesTableTableManager get grades =>
      $$GradesTableTableManager(_db, _db.grades);
  $$StreamsTableTableManager get streams =>
      $$StreamsTableTableManager(_db, _db.streams);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$ContentPacksTableTableManager get contentPacks =>
      $$ContentPacksTableTableManager(_db, _db.contentPacks);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$TopicsTableTableManager get topics =>
      $$TopicsTableTableManager(_db, _db.topics);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuestionTopicsTableTableManager get questionTopics =>
      $$QuestionTopicsTableTableManager(_db, _db.questionTopics);
}
