package be.business;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.TeacherGradeFile;

final class BinaryTeacherGradeReader {

    private static final int RECORD_SERIALIZED_STREAM_HEADER = 0;
    private static final int RECORD_CLASS_WITH_ID = 1;
    private static final int RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES = 4;
    private static final int RECORD_CLASS_WITH_MEMBERS_AND_TYPES = 5;
    private static final int RECORD_BINARY_OBJECT_STRING = 6;
    private static final int RECORD_BINARY_ARRAY = 7;
    private static final int RECORD_MEMBER_PRIMITIVE_TYPED = 8;
    private static final int RECORD_MEMBER_REFERENCE = 9;
    private static final int RECORD_OBJECT_NULL = 10;
    private static final int RECORD_MESSAGE_END = 11;
    private static final int RECORD_BINARY_LIBRARY = 12;
    private static final int RECORD_OBJECT_NULL_MULTIPLE_256 = 13;
    private static final int RECORD_OBJECT_NULL_MULTIPLE = 14;
    private static final int RECORD_ARRAY_SINGLE_PRIMITIVE = 15;
    private static final int RECORD_ARRAY_SINGLE_OBJECT = 16;
    private static final int RECORD_ARRAY_SINGLE_STRING = 17;

    private static final int BINARY_TYPE_PRIMITIVE = 0;
    private static final int BINARY_TYPE_SYSTEM_CLASS = 3;
    private static final int BINARY_TYPE_CLASS = 4;

    private static final int PRIMITIVE_BOOLEAN = 1;
    private static final int PRIMITIVE_BYTE = 2;
    private static final int PRIMITIVE_DOUBLE = 6;
    private static final int PRIMITIVE_INT16 = 7;
    private static final int PRIMITIVE_INT32 = 8;
    private static final int PRIMITIVE_INT64 = 9;
    private static final int PRIMITIVE_SINGLE = 11;
    private static final int PRIMITIVE_STRING = 18;

    private final byte[] bytes;
    private int offset;
    private int rootId;

    private final Map<Integer, Object> objects =
            new HashMap<>();
    private final Map<Integer, ClassMeta> metadata =
            new HashMap<>();

    private BinaryTeacherGradeReader(byte[] bytes) {
        this.bytes = bytes;
    }

    static boolean canRead(byte[] bytes) {
        if (bytes == null || bytes.length < 32 || bytes[0] != 0) {
            return false;
        }

        String head =
                new String(
                        bytes,
                        0,
                        Math.min(bytes.length, 512),
                        StandardCharsets.ISO_8859_1
                );

        return head.contains("FuGradeLib.TeacherGrade")
                || head.contains("FuGradeLib, Version=");
    }

    static TeacherGradeFile read(byte[] bytes) {
        return new BinaryTeacherGradeReader(bytes).read();
    }

    private TeacherGradeFile read() {
        parseRecord();

        while (offset < bytes.length) {
            Object record =
                    parseRecord();

            if (record instanceof MessageEnd) {
                break;
            }
        }

        return toTeacherGradeFile(resolve(new Ref(rootId)));
    }

    private Object parseRecord() {
        int recordType =
                readByte();

        return switch (recordType) {
            case RECORD_SERIALIZED_STREAM_HEADER ->
                    parseHeader();
            case RECORD_CLASS_WITH_ID ->
                    parseClassWithId();
            case RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES ->
                    parseClassWithMembersAndTypes(true);
            case RECORD_CLASS_WITH_MEMBERS_AND_TYPES ->
                    parseClassWithMembersAndTypes(false);
            case RECORD_BINARY_OBJECT_STRING ->
                    parseString();
            case RECORD_BINARY_ARRAY ->
                    parseBinaryArray();
            case RECORD_MEMBER_PRIMITIVE_TYPED ->
                    readPrimitive(readByte());
            case RECORD_MEMBER_REFERENCE ->
                    new Ref(readInt32());
            case RECORD_OBJECT_NULL ->
                    null;
            case RECORD_MESSAGE_END ->
                    new MessageEnd();
            case RECORD_BINARY_LIBRARY ->
                    parseLibrary();
            case RECORD_OBJECT_NULL_MULTIPLE_256 ->
                    new NullRun(readByte());
            case RECORD_OBJECT_NULL_MULTIPLE ->
                    new NullRun(readInt32());
            case RECORD_ARRAY_SINGLE_PRIMITIVE ->
                    parsePrimitiveArray();
            case RECORD_ARRAY_SINGLE_OBJECT, RECORD_ARRAY_SINGLE_STRING ->
                    parseObjectArray();
            default ->
                    throw new IllegalArgumentException(
                            "Unsupported .fg binary record: " + recordType
                                    + " at offset " + (offset - 1)
                    );
        };
    }

    private Object parseHeader() {
        rootId = readInt32();
        readInt32();
        readInt32();
        readInt32();

        return null;
    }

    private Object parseLibrary() {
        readInt32();
        readString();

        return null;
    }

    private Object parseString() {
        int objectId =
                readInt32();
        String value =
                readString();

        objects.put(objectId, value);

        return value;
    }

    private Object parseClassWithMembersAndTypes(
            boolean systemClass
    ) {

        ClassInfo classInfo =
                readClassInfo();
        TypeInfo typeInfo =
                readTypeInfo(classInfo.memberNames().size());

        int libraryId =
                systemClass ? 0 : readInt32();

        ClassMeta classMeta =
                new ClassMeta(
                        classInfo.typeName(),
                        classInfo.memberNames(),
                        typeInfo.binaryTypes(),
                        typeInfo.additionalInfos(),
                        libraryId
                );

        metadata.put(classInfo.objectId(), classMeta);

        Map<String, Object> object =
                new LinkedHashMap<>();
        object.put("__type", classInfo.typeName());
        objects.put(classInfo.objectId(), object);

        readMemberValues(classMeta, object);

        return object;
    }

    private Object parseClassWithId() {
        int objectId =
                readInt32();
        int metadataId =
                readInt32();

        ClassMeta classMeta =
                metadata.get(metadataId);

        if (classMeta == null) {
            throw new IllegalArgumentException(
                    "Missing .fg class metadata: " + metadataId
            );
        }

        Map<String, Object> object =
                new LinkedHashMap<>();
        object.put("__type", classMeta.typeName());
        objects.put(objectId, object);

        readMemberValues(classMeta, object);

        return object;
    }

    private void readMemberValues(
            ClassMeta classMeta,
            Map<String, Object> object
    ) {

        for (int i = 0; i < classMeta.memberNames().size(); i++) {
            object.put(
                    classMeta.memberNames().get(i),
                    readValue(
                            classMeta.binaryTypes().get(i),
                            classMeta.additionalInfos().get(i)
                    )
            );
        }
    }

    private Object readValue(
            int binaryType,
            AdditionalInfo additionalInfo
    ) {

        if (binaryType == BINARY_TYPE_PRIMITIVE) {
            return readPrimitive(additionalInfo.primitiveType());
        }

        return parseRecord();
    }

    private Object parseBinaryArray() {
        int objectId =
                readInt32();
        int binaryArrayType =
                readByte();
        int rank =
                readInt32();

        int length =
                1;

        for (int i = 0; i < rank; i++) {
            length *= readInt32();
        }

        if (binaryArrayType >= 3 && binaryArrayType <= 5) {
            for (int i = 0; i < rank; i++) {
                readInt32();
            }
        }

        int binaryType =
                readByte();
        AdditionalInfo additionalInfo =
                readAdditionalInfo(binaryType);

        List<Object> values =
                new ArrayList<>();
        objects.put(objectId, values);

        readArrayValues(values, length, binaryType, additionalInfo);

        return values;
    }

    private Object parseObjectArray() {
        int objectId =
                readInt32();
        int length =
                readInt32();

        List<Object> values =
                new ArrayList<>();
        objects.put(objectId, values);

        for (int i = 0; i < length; i++) {
            Object value =
                    parseRecord();

            if (value instanceof NullRun nullRun) {
                for (int n = 0; n < nullRun.count(); n++) {
                    values.add(null);
                }

                i += nullRun.count() - 1;
            } else {
                values.add(value);
            }
        }

        return values;
    }

    private Object parsePrimitiveArray() {
        int objectId =
                readInt32();
        int length =
                readInt32();
        int primitiveType =
                readByte();

        List<Object> values =
                new ArrayList<>();
        objects.put(objectId, values);

        for (int i = 0; i < length; i++) {
            values.add(readPrimitive(primitiveType));
        }

        return values;
    }

    private void readArrayValues(
            List<Object> values,
            int length,
            int binaryType,
            AdditionalInfo additionalInfo
    ) {

        for (int i = 0; i < length; i++) {
            Object value =
                    readValue(binaryType, additionalInfo);

            if (value instanceof NullRun nullRun) {
                for (int n = 0; n < nullRun.count(); n++) {
                    values.add(null);
                }

                i += nullRun.count() - 1;
            } else {
                values.add(value);
            }
        }
    }

    private ClassInfo readClassInfo() {
        int objectId =
                readInt32();
        String typeName =
                readString();
        int memberCount =
                readInt32();

        List<String> memberNames =
                new ArrayList<>();

        for (int i = 0; i < memberCount; i++) {
            memberNames.add(readString());
        }

        return new ClassInfo(objectId, typeName, memberNames);
    }

    private TypeInfo readTypeInfo(int memberCount) {
        List<Integer> binaryTypes =
                new ArrayList<>();

        for (int i = 0; i < memberCount; i++) {
            binaryTypes.add(readByte());
        }

        List<AdditionalInfo> additionalInfos =
                new ArrayList<>();

        for (int binaryType : binaryTypes) {
            additionalInfos.add(readAdditionalInfo(binaryType));
        }

        return new TypeInfo(binaryTypes, additionalInfos);
    }

    private AdditionalInfo readAdditionalInfo(int binaryType) {
        if (binaryType == BINARY_TYPE_PRIMITIVE) {
            return new AdditionalInfo(readByte(), null, 0);
        }

        if (binaryType == BINARY_TYPE_SYSTEM_CLASS) {
            return new AdditionalInfo(0, readString(), 0);
        }

        if (binaryType == BINARY_TYPE_CLASS) {
            String typeName =
                    readString();
            int libraryId =
                    readInt32();

            return new AdditionalInfo(0, typeName, libraryId);
        }

        return new AdditionalInfo(0, null, 0);
    }

    private Object readPrimitive(int primitiveType) {
        return switch (primitiveType) {
            case PRIMITIVE_BOOLEAN ->
                    readByte() != 0;
            case PRIMITIVE_BYTE ->
                    readByte();
            case PRIMITIVE_DOUBLE ->
                    readDouble();
            case PRIMITIVE_INT16 ->
                    readInt16();
            case PRIMITIVE_INT32 ->
                    readInt32();
            case PRIMITIVE_INT64 ->
                    readInt64();
            case PRIMITIVE_SINGLE ->
                    readSingle();
            case PRIMITIVE_STRING ->
                    readString();
            default ->
                    throw new IllegalArgumentException(
                            "Unsupported .fg primitive type: "
                                    + primitiveType
                    );
        };
    }

    private TeacherGradeFile toTeacherGradeFile(Object root) {
        Map<String, Object> rootMap =
                asMap(root);

        TeacherGradeFile teacherGrade =
                new TeacherGradeFile();

        teacherGrade.setVersion(stringValue(rootMap, "Version"));
        teacherGrade.setSemester(stringValue(rootMap, "Semester"));
        teacherGrade.setLogin(stringValue(rootMap, "Login"));
        teacherGrade.setPassword(stringValue(rootMap, "Password"));

        for (Object subjectClassValue
                : listValues(rootMap.get("SubjectClassGrades"))) {

            Map<String, Object> subjectClassMap =
                    asMap(subjectClassValue);

            FgSubjectClassGrade subjectClass =
                    new FgSubjectClassGrade();

            subjectClass.setSubject(
                    stringValue(
                            subjectClassMap,
                            "Subject",
                            "<Subject>k__BackingField"
                    )
            );
            subjectClass.setClassName(
                    stringValue(
                            subjectClassMap,
                            "Class",
                            "<Class>k__BackingField"
                    )
            );

            for (Object componentValue
                    : listValues(
                    field(
                            subjectClassMap,
                            "Components",
                            "<Components>k__BackingField"
                    )
            )) {
                String component =
                        stringValue(componentValue);

                if (component == null) {
                    continue;
                }

                subjectClass.getComponents()
                        .add(component);
            }

            for (Object studentValue
                    : listValues(
                    field(
                            subjectClassMap,
                            "Students",
                            "<Students>k__BackingField"
                    )
            )) {
                subjectClass.getStudents()
                        .add(toStudent(studentValue));
            }

            teacherGrade.getSubjectClassGrades()
                    .add(subjectClass);
        }

        return teacherGrade;
    }

    private FgStudent toStudent(Object value) {
        Map<String, Object> studentMap =
                asMap(value);

        FgStudent student =
                new FgStudent();

        student.setRoll(
                stringValue(
                        studentMap,
                        "Roll",
                        "<Roll>k__BackingField"
                )
        );
        student.setName(
                stringValue(
                        studentMap,
                        "Name",
                        "<Name>k__BackingField"
                )
        );
        student.setComment(
                stringValue(
                        studentMap,
                        "Comment",
                        "<Comment>k__BackingField"
                )
        );

        for (Object gradeValue
                : listValues(
                field(
                        studentMap,
                        "Grades",
                        "<Grades>k__BackingField"
                )
        )) {
            student.getGrades()
                    .add(toGradeComponent(gradeValue));
        }

        return student;
    }

    private FgGradeComponent toGradeComponent(Object value) {
        Map<String, Object> gradeMap =
                asMap(value);

        FgGradeComponent component =
                new FgGradeComponent();

        component.setComponent(
                stringValue(
                        gradeMap,
                        "Component",
                        "<Component>k__BackingField"
                )
        );
        component.setGrade(
                floatValue(
                        field(
                                gradeMap,
                                "Grade",
                                "<Grade>k__BackingField"
                        )
                )
        );

        return component;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> asMap(Object value) {
        Object resolved =
                resolve(value);

        if (resolved instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }

        return Map.of();
    }

    private List<Object> listValues(Object value) {
        Object resolved =
                resolve(value);

        if (resolved instanceof Map<?, ?> map
                && map.containsKey("_items")) {

            List<Object> items =
                    listValues(map.get("_items"));
            int size =
                    intValue(map.get("_size"));

            return items.subList(
                    0,
                    Math.min(size, items.size())
            );
        }

        if (resolved instanceof List<?> list) {
            return list.stream()
                    .map(this::resolve)
                    .toList();
        }

        return List.of();
    }

    private Object resolve(Object value) {
        if (value instanceof Ref ref) {
            return resolve(objects.get(ref.objectId()));
        }

        return value;
    }

    private Object field(
            Map<String, Object> map,
            String... names
    ) {

        for (String name : names) {
            if (map.containsKey(name)) {
                return map.get(name);
            }
        }

        return null;
    }

    private String stringValue(
            Map<String, Object> map,
            String... names
    ) {

        return stringValue(field(map, names));
    }

    private String stringValue(Object value) {
        Object resolved =
                resolve(value);

        return resolved == null ? null : resolved.toString();
    }

    private Float floatValue(Object value) {
        Object resolved =
                resolve(value);

        if (resolved instanceof Number number) {
            return number.floatValue();
        }

        return null;
    }

    private int intValue(Object value) {
        Object resolved =
                resolve(value);

        if (resolved instanceof Number number) {
            return number.intValue();
        }

        return 0;
    }

    private String nullToEmpty(Object value) {
        return value == null ? "" : value.toString();
    }

    private int readByte() {
        return bytes[offset++] & 0xFF;
    }

    private short readInt16() {
        short value =
                (short) ((bytes[offset] & 0xFF)
                        | ((bytes[offset + 1] & 0xFF) << 8));

        offset += 2;

        return value;
    }

    private int readInt32() {
        int value =
                (bytes[offset] & 0xFF)
                        | ((bytes[offset + 1] & 0xFF) << 8)
                        | ((bytes[offset + 2] & 0xFF) << 16)
                        | ((bytes[offset + 3] & 0xFF) << 24);

        offset += 4;

        return value;
    }

    private long readInt64() {
        long value =
                0;

        for (int i = 0; i < 8; i++) {
            value |= (long) (bytes[offset + i] & 0xFF)
                    << (8 * i);
        }

        offset += 8;

        return value;
    }

    private float readSingle() {
        return Float.intBitsToFloat(readInt32());
    }

    private double readDouble() {
        return Double.longBitsToDouble(readInt64());
    }

    private String readString() {
        int length =
                read7BitEncodedInt();

        String value =
                new String(
                        bytes,
                        offset,
                        length,
                        StandardCharsets.UTF_8
                );

        offset += length;

        return value;
    }

    private int read7BitEncodedInt() {
        int count =
                0;
        int shift =
                0;

        while (shift != 35) {
            int value =
                    readByte();

            count |= (value & 0x7F) << shift;

            if ((value & 0x80) == 0) {
                return count;
            }

            shift += 7;
        }

        throw new IllegalArgumentException(
                "Invalid .fg binary string length"
        );
    }

    private record ClassInfo(
            int objectId,
            String typeName,
            List<String> memberNames
    ) {
    }

    private record TypeInfo(
            List<Integer> binaryTypes,
            List<AdditionalInfo> additionalInfos
    ) {
    }

    private record ClassMeta(
            String typeName,
            List<String> memberNames,
            List<Integer> binaryTypes,
            List<AdditionalInfo> additionalInfos,
            int libraryId
    ) {
    }

    private record AdditionalInfo(
            int primitiveType,
            String typeName,
            int libraryId
    ) {
    }

    private record Ref(int objectId) {
    }

    private record NullRun(int count) {
    }

    private record MessageEnd() {
    }
}
