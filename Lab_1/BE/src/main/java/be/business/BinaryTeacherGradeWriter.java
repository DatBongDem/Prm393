package be.business;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.TeacherGradeFile;

final class BinaryTeacherGradeWriter {

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
    private static final int RECORD_ARRAY_SINGLE_STRING = 17;

    private static final int BINARY_ARRAY_SINGLE = 0;

    private static final int BINARY_TYPE_PRIMITIVE = 0;
    private static final int BINARY_TYPE_STRING = 1;
    private static final int BINARY_TYPE_SYSTEM_CLASS = 3;
    private static final int BINARY_TYPE_CLASS = 4;
    private static final int BINARY_TYPE_STRING_ARRAY = 6;

    private static final int PRIMITIVE_INT32 = 8;
    private static final int PRIMITIVE_SINGLE = 11;

    private static final int LIBRARY_ID = 2;

    private static final String FUGRADE_LIBRARY =
            "FuGradeLib, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null";
    private static final String MSCORLIB =
            "mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";

    private static final String TEACHER_GRADE_TYPE =
            "FuGradeLib.TeacherGrade";
    private static final String SUBJECT_CLASS_TYPE =
            "FuGradeLib.SubjectClassGrade";
    private static final String STUDENT_TYPE =
            "FuGradeLib.Student";
    private static final String GRADE_COMPONENT_TYPE =
            "FuGradeLib.GradeComponent";

    private static final String SUBJECT_CLASS_LIST_TYPE =
            listType(SUBJECT_CLASS_TYPE + ", " + FUGRADE_LIBRARY);
    private static final String STUDENT_LIST_TYPE =
            listType(STUDENT_TYPE + ", " + FUGRADE_LIBRARY);
    private static final String GRADE_COMPONENT_LIST_TYPE =
            listType(GRADE_COMPONENT_TYPE + ", " + FUGRADE_LIBRARY);
    private static final String STRING_LIST_TYPE =
            listType("System.String, " + MSCORLIB);

    private final ByteArrayOutputStream out =
            new ByteArrayOutputStream();
    private final Map<String, Integer> metadataIds =
            new HashMap<>();
    private final List<Runnable> pendingRecords =
            new ArrayList<>();

    private int nextObjectId = 1;

    private BinaryTeacherGradeWriter() {
    }

    static byte[] write(TeacherGradeFile teacherGrade) {
        return new BinaryTeacherGradeWriter()
                .writeFile(teacherGrade);
    }

    private static String listType(String itemType) {
        return "System.Collections.Generic.List`1[[" + itemType + "]]";
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private byte[] writeFile(TeacherGradeFile teacherGrade) {
        int rootId =
                nextObjectId();

        writeHeader(rootId);
        writeLibrary();
        writeTeacherGrade(rootId, teacherGrade);
        flushPendingRecords();
        writeByte(RECORD_MESSAGE_END);

        return out.toByteArray();
    }

    private void writeHeader(int rootId) {
        writeByte(RECORD_SERIALIZED_STREAM_HEADER);
        writeInt32(rootId);
        writeInt32(-1);
        writeInt32(1);
        writeInt32(0);
    }

    private void writeLibrary() {
        writeByte(RECORD_BINARY_LIBRARY);
        writeInt32(LIBRARY_ID);
        writeString(FUGRADE_LIBRARY);
    }

    private void writeTeacherGrade(
            int objectId,
            TeacherGradeFile teacherGrade
    ) {

        writeClassStart(
                TEACHER_GRADE_TYPE,
                objectId,
                false,
                List.of(
                        member("Version", BINARY_TYPE_STRING),
                        member("Semester", BINARY_TYPE_STRING),
                        member("Login", BINARY_TYPE_STRING),
                        member("Password", BINARY_TYPE_STRING),
                        member(
                                "SubjectClassGrades",
                                BINARY_TYPE_SYSTEM_CLASS,
                                SUBJECT_CLASS_LIST_TYPE
                        )
                )
        );

        writeStringObject(teacherGrade == null
                ? null
                : teacherGrade.getVersion());
        writeStringObject(teacherGrade == null
                ? null
                : teacherGrade.getSemester());
        writeStringObject(teacherGrade == null
                ? null
                : teacherGrade.getLogin());
        writeStringObject(teacherGrade == null
                ? ""
                : nullToEmpty(teacherGrade.getPassword()));
        writeSubjectClassListReference(teacherGrade == null
                ? List.of()
                : teacherGrade.getSubjectClassGrades());
    }

    private void writeSubjectClassListReference(
            List<FgSubjectClassGrade> values
    ) {

        List<FgSubjectClassGrade> items =
                values == null ? List.of() : values;

        writeReferenceToPending(
                objectId -> writeList(
                        objectId,
                        SUBJECT_CLASS_LIST_TYPE,
                        SUBJECT_CLASS_TYPE + "[]",
                        items.size(),
                        () -> writeClassArrayReference(
                                SUBJECT_CLASS_TYPE,
                                items,
                                this::writeSubjectClass
                        )
                )
        );
    }

    private void writeStudentListReference(
            List<FgStudent> values
    ) {

        List<FgStudent> items =
                values == null ? List.of() : values;

        writeReferenceToPending(
                objectId -> writeList(
                        objectId,
                        STUDENT_LIST_TYPE,
                        STUDENT_TYPE + "[]",
                        items.size(),
                        () -> writeClassArrayReference(
                                STUDENT_TYPE,
                                items,
                                this::writeStudent
                        )
                )
        );
    }

    private void writeGradeComponentListReference(
            List<FgGradeComponent> values
    ) {

        List<FgGradeComponent> items =
                values == null ? List.of() : values;

        writeReferenceToPending(
                objectId -> writeList(
                        objectId,
                        GRADE_COMPONENT_LIST_TYPE,
                        GRADE_COMPONENT_TYPE + "[]",
                        items.size(),
                        () -> writeClassArrayReference(
                                GRADE_COMPONENT_TYPE,
                                items,
                                this::writeGradeComponent
                        )
                )
        );
    }

    private void writeStringListReference(List<String> values) {
        List<String> items =
                values == null ? List.of() : values;

        writeReferenceToPending(
                objectId -> writeStringListObject(
                        objectId,
                        STRING_LIST_TYPE,
                        items.size(),
                        () -> writeStringArrayReference(items)
                )
        );
    }

    private void writeList(
            int objectId,
            String typeName,
            String arrayTypeName,
            int size,
            Runnable writeItems
    ) {

        writeClassStart(
                typeName,
                objectId,
                true,
                List.of(
                        member(
                                "_items",
                                BINARY_TYPE_CLASS,
                                arrayTypeName,
                                LIBRARY_ID
                        ),
                        member(
                                "_size",
                                BINARY_TYPE_PRIMITIVE,
                                PRIMITIVE_INT32
                        ),
                        member(
                                "_version",
                                BINARY_TYPE_PRIMITIVE,
                                PRIMITIVE_INT32
                        )
                )
        );

        writeItems.run();
        writeInt32(size);
        writeInt32(size);
    }

    private void writeStringListObject(
            int objectId,
            String typeName,
            int size,
            Runnable writeItems
    ) {

        writeClassStart(
                typeName,
                objectId,
                true,
                List.of(
                        member("_items", BINARY_TYPE_STRING_ARRAY),
                        member(
                                "_size",
                                BINARY_TYPE_PRIMITIVE,
                                PRIMITIVE_INT32
                        ),
                        member(
                                "_version",
                                BINARY_TYPE_PRIMITIVE,
                                PRIMITIVE_INT32
                        )
                )
        );

        writeItems.run();
        writeInt32(size);
        writeInt32(size);
    }

    private <T> void writeClassArrayReference(
            String elementTypeName,
            List<T> items,
            ObjectWriter<T> writer
    ) {

        writeReferenceToPending(
                objectId -> writeClassArray(
                        objectId,
                        elementTypeName,
                        items,
                        writer
                )
        );
    }

    private <T> void writeClassArray(
            int objectId,
            String elementTypeName,
            List<T> items,
            ObjectWriter<T> writer
    ) {

        writeByte(RECORD_BINARY_ARRAY);
        writeInt32(objectId);
        writeByte(BINARY_ARRAY_SINGLE);
        writeInt32(1);
        writeInt32(items.size());
        writeByte(BINARY_TYPE_CLASS);
        writeString(elementTypeName);
        writeInt32(LIBRARY_ID);

        for (T item : items) {
            if (item == null) {
                writeNull();
            } else {
                writeReferenceToPending(
                        itemId -> writer.write(itemId, item)
                );
            }
        }
    }

    private void writeStringArrayReference(List<String> items) {
        writeReferenceToPending(
                objectId -> writeStringArray(objectId, items)
        );
    }

    private void writeStringArray(
            int objectId,
            List<String> items
    ) {
        writeByte(RECORD_ARRAY_SINGLE_STRING);
        writeInt32(objectId);
        writeInt32(items.size());

        for (String item : items) {
            writeStringObject(item);
        }
    }

    private void writeSubjectClass(
            int objectId,
            FgSubjectClassGrade subjectClass
    ) {
        writeClassStart(
                SUBJECT_CLASS_TYPE,
                objectId,
                false,
                List.of(
                        member("Subject", BINARY_TYPE_STRING),
                        member("Class", BINARY_TYPE_STRING),
                        member(
                                "Students",
                                BINARY_TYPE_SYSTEM_CLASS,
                                STUDENT_LIST_TYPE
                        ),
                        member(
                                "Components",
                                BINARY_TYPE_SYSTEM_CLASS,
                                STRING_LIST_TYPE
                        )
                )
        );

        writeStringObject(subjectClass.getSubject());
        writeStringObject(subjectClass.getClassName());
        writeStudentListReference(subjectClass.getStudents());
        writeStringListReference(subjectClass.getComponents());
    }

    private void writeStudent(
            int objectId,
            FgStudent student
    ) {
        writeClassStart(
                STUDENT_TYPE,
                objectId,
                false,
                List.of(
                        member("<Roll>k__BackingField", BINARY_TYPE_STRING),
                        member("<Name>k__BackingField", BINARY_TYPE_STRING),
                        member(
                                "<Grades>k__BackingField",
                                BINARY_TYPE_SYSTEM_CLASS,
                                GRADE_COMPONENT_LIST_TYPE
                        ),
                        member("<Comment>k__BackingField", BINARY_TYPE_STRING)
                )
        );

        writeStringObject(student.getRoll());
        writeStringObject(student.getName());
        writeGradeComponentListReference(student.getGrades());
        writeStringObject(student.getComment());
    }

    private void writeGradeComponent(
            int objectId,
            FgGradeComponent gradeComponent
    ) {
        writeClassStart(
                GRADE_COMPONENT_TYPE,
                objectId,
                false,
                List.of(
                        member(
                                "<Component>k__BackingField",
                                BINARY_TYPE_STRING
                        ),
                        member(
                                "<Grade>k__BackingField",
                                BINARY_TYPE_SYSTEM_CLASS,
                                "System.Single"
                        )
                )
        );

        writeStringObject(gradeComponent.getComponent());
        writeNullableSingle(gradeComponent.getGrade());
    }

    private void flushPendingRecords() {
        for (int index = 0; index < pendingRecords.size(); index++) {
            pendingRecords.get(index)
                    .run();
        }
    }

    private void writeReferenceToPending(PendingObjectWriter writer) {
        int objectId =
                nextObjectId();

        writeMemberReference(objectId);
        pendingRecords.add(() -> writer.write(objectId));
    }

    private void writeMemberReference(int objectId) {
        writeByte(RECORD_MEMBER_REFERENCE);
        writeInt32(objectId);
    }

    private void writeClassStart(
            String typeName,
            int objectId,
            boolean systemClass,
            List<Member> members
    ) {

        Integer metadataId =
                metadataIds.get(typeName);

        if (metadataId != null) {
            writeByte(RECORD_CLASS_WITH_ID);
            writeInt32(objectId);
            writeInt32(metadataId);
            return;
        }

        metadataIds.put(typeName, objectId);
        writeByte(
                systemClass
                        ? RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES
                        : RECORD_CLASS_WITH_MEMBERS_AND_TYPES
        );
        writeClassInfo(objectId, typeName, members);
        writeMemberTypeInfo(members);

        if (!systemClass) {
            writeInt32(LIBRARY_ID);
        }
    }

    private void writeClassInfo(
            int objectId,
            String typeName,
            List<Member> members
    ) {

        writeInt32(objectId);
        writeString(typeName);
        writeInt32(members.size());

        for (Member member : members) {
            writeString(member.name());
        }
    }

    private void writeMemberTypeInfo(List<Member> members) {
        for (Member member : members) {
            writeByte(member.binaryType());
        }

        for (Member member : members) {
            if (member.binaryType() == BINARY_TYPE_PRIMITIVE) {
                writeByte(member.primitiveType());
            } else if (member.binaryType() == BINARY_TYPE_SYSTEM_CLASS) {
                writeString(member.typeName());
            } else if (member.binaryType() == BINARY_TYPE_CLASS) {
                writeString(member.typeName());
                writeInt32(member.libraryId());
            }
        }
    }

    private void writeStringObject(String value) {
        if (value == null) {
            writeNull();
            return;
        }

        writeByte(RECORD_BINARY_OBJECT_STRING);
        writeInt32(nextObjectId());
        writeString(value);
    }

    private void writeNullableSingle(Float value) {
        if (value == null) {
            writeNull();
            return;
        }

        writeByte(RECORD_MEMBER_PRIMITIVE_TYPED);
        writeByte(PRIMITIVE_SINGLE);
        writeSingle(Math.round(value * 10.0f) / 10.0f);
    }

    private void writeNull() {
        writeByte(RECORD_OBJECT_NULL);
    }

    private void writeString(String value) {
        byte[] bytes =
                value.getBytes(StandardCharsets.UTF_8);

        write7BitEncodedInt(bytes.length);
        out.writeBytes(bytes);
    }

    private void write7BitEncodedInt(int value) {
        int remaining =
                value;

        while (remaining >= 0x80) {
            writeByte((remaining & 0x7F) | 0x80);
            remaining >>>= 7;
        }

        writeByte(remaining);
    }

    private void writeSingle(float value) {
        writeInt32(Float.floatToIntBits(value));
    }

    private void writeInt32(int value) {
        out.write(value & 0xFF);
        out.write((value >>> 8) & 0xFF);
        out.write((value >>> 16) & 0xFF);
        out.write((value >>> 24) & 0xFF);
    }

    private void writeByte(int value) {
        out.write(value & 0xFF);
    }

    private int nextObjectId() {
        while (nextObjectId == LIBRARY_ID) {
            nextObjectId++;
        }

        return nextObjectId++;
    }

    private static Member member(String name, int binaryType) {
        return new Member(name, binaryType, 0, null, 0);
    }

    private static Member member(
            String name,
            int binaryType,
            int primitiveType
    ) {
        return new Member(name, binaryType, primitiveType, null, 0);
    }

    private static Member member(
            String name,
            int binaryType,
            String typeName
    ) {
        return new Member(name, binaryType, 0, typeName, 0);
    }

    private static Member member(
            String name,
            int binaryType,
            String typeName,
            int libraryId
    ) {
        return new Member(name, binaryType, 0, typeName, libraryId);
    }

    private record Member(
            String name,
            int binaryType,
            int primitiveType,
            String typeName,
            int libraryId
    ) {
    }

    @FunctionalInterface
    private interface ObjectWriter<T> {
        void write(int objectId, T value);
    }

    @FunctionalInterface
    private interface PendingObjectWriter {
        void write(int objectId);
    }
}
