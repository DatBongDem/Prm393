package be.business.dtos;

public class AIQuery {

    private String type;     // query / aggregate / chat
    private String field;    // total / practical / finalExam
    private String operator; // > < =
    private String value;    
    private String aggregate; // max / min / avg / count   ⭐ NEW

    // getter setter
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getField() { return field; }
    public void setField(String field) { this.field = field; }

    public String getOperator() { return operator; }
    public void setOperator(String operator) { this.operator = operator; }

    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }

    public String getAggregate() { return aggregate; }
    public void setAggregate(String aggregate) { this.aggregate = aggregate; }
}