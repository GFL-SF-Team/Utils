/* Class: LightningResult
 * Test Class: LightningResultTest
 * @author: Dmytro Lambru
 * @date: 25.08.2018
 * @description: Response wrapper for Lightning Components
 * @history:
 */
public class LightningResult {

	@AuraEnabled
	/* Successful(TRUE) or not successful(FALSE) operation */
	public Boolean success {get; set;}

	@AuraEnabled
	/* For send a message */
	public String message {get; set;}

	@AuraEnabled
	/* Data in JSON string */
	public String data {get; set;}

	@AuraEnabled
	/* Code number for the error */
	public Integer code {get; set;}

	/* For success response - set JSON data  */
	public LightningResult setResult(String data) {
		this.data = data;
		this.success = TRUE;
		return this;
	}

	/* For error response - set message */
	public LightningResult setError(String message) {
		this.message = message;
		this.success = FALSE;
		return this;
	}

	/* For error response with error code number */
	public LightningResult setError(Integer code) {
		this.code = code;
		this.success = FALSE;
		return this;
	}

	/* For error response with message and error code number */
	public LightningResult setError(String message, Integer code) {
		this.message = message;
		this.code = code;
		this.success = FALSE;
		return this;
	}
}