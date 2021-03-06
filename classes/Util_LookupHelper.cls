/* @name: Util_LookupHelper
 * @test: Util_LookupTest
 * @author: Dmytro Lambru
 * @date: 22.05.19
 * @description: Helper for 'Util_LookupController'
 */
public with sharing class Util_LookupHelper {
    
    private static Schema.DescribeSObjectResult objectDescribe {get;set;}

	/**
	 * @description             search for records by config
	 * @param  stringToSearch   string with value for search
	 * @param  searchConfig     search config
	 * @return                  list with wrapped records
	 */
    public static Util_D_RecordInfo[] searchRecords(String stringToSearch, Util_D_SearchConfig searchConfig) {
		Util_LookupHelper.objectDescribe = Schema.describeSObjects(new String[]{searchConfig.objectName})[0];

        String queryString = generateQueryString(stringToSearch, searchConfig);
        
        SObject[] resultRecordList = Database.query(queryString);
        
        return processResultRecords(resultRecordList, searchConfig);
    }

	/**
	 * @description             generating query string from config
	 * @param  stringToSearch   string with value for search
	 * @param  searchConfig     search config
	 * @return                  query string
	 */
    public static String generateQueryString(String stringToSearch, Util_D_SearchConfig searchConfig) {
		stringToSearch = String.escapeSingleQuotes(stringToSearch);

		String queryString = 'SELECT ';

		// add fields
		queryString += generateFields(searchConfig.fieldForQueryList) + ' ';

		// add target object
		queryString += 'FROM ' + searchConfig.objectName + ' ';

		// add WHERE
		queryString += 'WHERE ';
		queryString += generateWhereClauseWithFilterCriterion(searchConfig);
		queryString += generateWhereClauseWithLike(stringToSearch, searchConfig) + ' ';

		// add ORDER BY
		queryString += generateOrderByClause(searchConfig) + ' ';

        // add LIMIT
        queryString += 'LIMIT ' + searchConfig.numberOfRecords;

		return queryString;
	}

	/**
	 * @description               generation of string with fields for query.
	 *                            e.g. 'SomeField1__c, SomeField2__c, SomeField3__c'
     *
	 * @param  fieldForQueryList  list with API names of fields
	 * @return                    generated string
	 */
	public static String generateFields(String[] fieldForQueryList) {
		
		for (Integer index = 0, length = fieldForQueryList.size(); index < length; index++) {
			
            // remove field from list, if user doesn't has access to the field
			if (!Utils.schemaCheckObjectFieldIsAccessible(Util_LookupHelper.objectDescribe, fieldForQueryList[index])) {
				fieldForQueryList.remove(index);
			}
		}

		fieldForQueryList.add('Id');

		return String.join(fieldForQueryList, ',');
	}

	/**
	 * @description             generation of string with fields for filtering in 'WHERE' clause.
	 *                          e.g. 'FieldName1__c = 8 AND FieldName2__c <> "some value"'
	 *
	 * @param  searchConfig     search config
	 * @return                  generated string
	 */
	public static String generateWhereClauseWithFilterCriterion(Util_D_SearchConfig searchConfig) {
		String whereClauseString = '';

		if (searchConfig.fieldForFilterCriterionList != null) {

			for (Util_D_SearchConfig.FieldForFilterCriterion fieldInfo : searchConfig.fieldForFilterCriterionList) {
				
				if (fieldInfo.typeOfValue == 'String') {
					fieldInfo.value = '\'' + fieldInfo.value + '\'';
				}

				whereClauseString += fieldInfo.fieldName + ' ' + fieldInfo.condition + ' ' + fieldInfo.value + ' ';
				whereClauseString += 'AND ';
			}
		}

		return whereClauseString;
	}

	/**
	 * @description             generating a string with fields to search value through the keyword 'LIKE'.
	 *                          e.g. 'FieldName1__c LIKE "%some value%" OR FieldName2__c LIKE "%some value%"'
	 *
	 * @param  stringToSearch   string with value for search
	 * @param  searchConfig     search config
	 * @return                  generated string
	 */
	public static String generateWhereClauseWithLike(String stringToSearch, Util_D_SearchConfig searchConfig) {
		String whereClauseString = '(';

		for (Integer i = 0, length = searchConfig.fieldForSearchList.size(); i < length; i++) {

			if (i != 0) whereClauseString += 'OR ';

			whereClauseString += searchConfig.fieldForSearchList[i] + ' LIKE \'%' + stringToSearch + '%\' ';
		}

    	whereClauseString += ')';

		return whereClauseString;
	}

	/**
	 * @description         string generation with fields for ordering.
	 *                      e.g. 'ORDER BY FieldName1__c, FieldName2__c'
     *
	 * @param  searchConfig search config
	 * @return              generated string
	 */
	public static String generateOrderByClause(Util_D_SearchConfig searchConfig) {
	String orderByClauseString = '';

		if (
			searchConfig.fieldForOrderList != NULL
			&& !searchConfig.fieldForOrderList.isEmpty()
		) {
			orderByClauseString = 'ORDER BY ' + String.join(searchConfig.fieldForOrderList, ',');
		}

		return orderByClauseString;
	}

    /**
     * @description             wrap records with full information about it
     * @param  resultRecordList record list
     * @param  searchConfig     search config
     * @return                  list with wrapped records
     */
	public static Util_D_RecordInfo[] processResultRecords(SObject[] resultRecordList, Util_D_SearchConfig searchConfig) {
		Util_D_RecordInfo[] recordInfoList = new Util_D_RecordInfo[]{};

		for (SObject record : resultRecordList) {
			Util_D_RecordInfo recordInfo = new Util_D_RecordInfo();

			recordInfo.recordId = record.Id;
			recordInfo.record = record;
			recordInfo.fieldToShowInfoList = generateFieldsToShow(record, searchConfig);

			// if the displayed fields for the user are empty due to access, there is no point in adding a 'recordInfo'
			if (!recordInfo.fieldToShowInfoList.isEmpty()) {
				recordInfoList.add(recordInfo);
			}
		}

		return recordInfoList;
	}

    /**
     * @description           create a list with information about the fields to display in the record
     * @param  record         record from org
     * @param  searchConfig   search config
     * @return                list with fields to show info
     */
	public static Util_D_RecordInfo.FieldToShowInfo[] generateFieldsToShow(SObject record, Util_D_SearchConfig searchConfig) {
		Util_D_RecordInfo.FieldToShowInfo[] fieldToShowInfoList = new Util_D_RecordInfo.FieldToShowInfo[]{};
			
		for (Util_D_SearchConfig.FieldToShow fieldToShow : searchConfig.fieldToShowList) {
			
			// if record has this field and user has access to the field
			if (record.isSet(fieldToShow.fieldName)) {
				Util_D_RecordInfo.FieldToShowInfo fieldToShowInfo = new Util_D_RecordInfo.FieldToShowInfo();

				fieldToShowInfo.fieldLabel = getFieldLabel(record, fieldToShow);
				fieldToShowInfo.fieldName = fieldToShow.fieldName;
				fieldToShowInfo.fieldValue = record.get(fieldToShow.fieldName);
				fieldToShowInfo.isFieldLabelHidden = fieldToShow.isFieldLabelHidden;
				
				fieldToShowInfoList.add(fieldToShowInfo);
			}
		}
			
		return fieldToShowInfoList;
	}
	
	/**
     * @description           getting a label for a field from a config or org
     * @param  record         record from org
     * @param  fieldToShow    field to show info
     * @return                string with label
     */
	public static String getFieldLabel(SObject record, Util_D_SearchConfig.FieldToShow fieldToShow) {
		String fieldLabel;

		if (!fieldToShow.isFieldLabelHidden) {
			fieldLabel = fieldToShow.fieldLabel;

			if (fieldLabel == null) {
				// get label from SObject describe
				fieldLabel = Utils.getFieldLabelFormSObject(Util_LookupHelper.objectDescribe, fieldToShow.fieldName);
			}
		}

		return fieldLabel;
	}
}
