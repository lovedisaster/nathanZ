<?php
/**
 * Defines the StorePage page type
 */

class StorePage extends Page {
	
	static $db = array(
		"AddressLine1" => "Text",
		"AddressLine2" => "Text",
		"AddressLine3" => "Text",
		"AddressSuburb" => "Text",
		"AddressPostcode" => "Text",
		"AddressState" => "Enum('VIC, NSW, QLD, SA, WA, NT, TAS, ACT','VIC')",
		"AddressStateOther" => "Text",
		"AddressCountry" => "Text",
		"Phone" => "Text",
		"Fax" => "Text",
		"Email" => "Text",
		"OpeningHours" => "Text",
		//givex stuff
		"GivexID" => "Text",
		"HideFromSignup" => "Boolean",
		"AddressLongitude" => "Text",
		"AddressLatitude" => "Text"
		);
	
	static $has_one = array(
		);
		
	static $allowed_children = "none";
	
	/* get the CMS fields for the custom data items */
	function getCMSFields() {
		$fields = parent::getCMSFields();
		
		/* add address details */
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressLine1', 'Line 1'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressLine2', 'Line 2'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressLine3', 'Line 3'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressSuburb', 'Suburb'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressPostcode', 'Postcode'));
		$fields->addFieldToTab('Root.Content.Address', new DropdownField(
			'State', 
			'State', 
			singleton('StorePage')->dbObject('AddressState')->enumValues()));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressStateOther', 'State (Other)'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressCountry', 'Country'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressLongitude','Longitude(Example:43.834526782236814 )'));
		$fields->addFieldToTab('Root.Content.Address', new TextField('AddressLatitude','Latitude(Example: -37.265625)'));

		$fields->addFieldToTab('Root.Content.ContactDetails', new TextField('Phone', 'Phone'));
		$fields->addFieldToTab('Root.Content.ContactDetails', new TextField('Fax', 'Fax'));
		$fields->addFieldToTab('Root.Content.ContactDetails', new TextField('Email', 'Email'));

		$fields->addFieldToTab('Root.Content.Main', new TextareaField('OpeningHours', 'Opening Hours', 10));
		
		// add givex ID
		$fields->addFieldToTab('Root.Content.SignupSettings', new TextField('GivexID', 'Associated Givex ID'));
		$fields->addFieldToTab('Root.Content.SignupSettings', new CheckboxField('HideFromSignup', 'Hide from signup?'));
		
		/* remove some fields */
		$fields->removeFieldFromTab('Root.Content.Main', 'Content');

		return $fields;
	}
	
	
	/**
	 * Fetches the list of stores for signup.
	 */
	public static function FetchAllForSignup($includeHidden = false) {
		$stores = DataObject::get('StorePage', "GivexID IS NOT NULL AND GivexID != ''" . (!$includeHidden ? ' AND HideFromSignup != 1' : ''), 'Title');
		$output = array();
		if ($stores && count($stores->items)) {
			foreach ($stores as $s) {
				if ($s->AddressStateOther) {
					$output[$s->GivexID] = $s->Title . " (" . $s->AddressStateOther . ")";
				}
				else {
					$output[$s->GivexID] = $s->Title . " (" . $s->AddressState . ")";
				}
			}
		}
		return $output;
	}
	
	public function IsStorePage() {
		return true;
	}
	
	/*
	 * Checks if the current object has a valid address or not
	 */
	public function HasAddress() {
		$line1 = $this->AddressLine1;	
		$line2 = $this->AddressLine2;	
		$line3 = $this->AddressLine3;	
		$suburb = $this->AddressSuburb;
		return (($line1 || $line2 || $line3) && $suburb);
	}
	
	public function HasCountry() {
		return $this->AddressCountry &&
			$this->AddressCountry != "" &&
			strtoupper($this->AddressCountry) != "AUS" &&
			strtoupper($this->AddressCountry) != "AUSTRALIA";
	}
	
	public function HasContact() {
		return $this->Phone || $this->Fax || $this->Email;
	}
	
	//If any of this is null, show no result error message.
	public function HasEarthTarget(){
		return ($this->AddressLatitude && $this->AddressLongitude);
	}
	
	public function HasLongitude(){
		return $this->AddressLongitude;
	}
	
	public function HasLatitude(){
		return $this->AddressLatitude;
	}
}
	
class StorePage_Controller extends Page_Controller {
	
	/* initialise the content page */
	public function init() {
		parent::init();
	}	

	public function StoreSearchForm()
	{		
		$f = new FieldSet();
		$a = new FieldSet(
			new FormAction('doStoreSearch', 'Submit')
			);
		$f->push(new DropdownField(
			$name = "SearchOption",
			$title = "Postcode or Suburb",
			$source = array(
						"1" => "Search by Postcode",
						"2" => "Search by Suburb"
						),
					$value = "1" 
					));
		//SuburbValue is either postcode or suburb name depends on what criteria the user select. 
		$f->push(new TextField("SuburbValue", "By PostCode or Suburb"));
		$f->push(new OptionsetField(
			$name = "SearchMethod",
			$title = "View By",
			$source = array(
						"1" => "Store",
						"2" => "Stockist"
						),
					$value = "1" 
					));
		
		$customForm = new Form($this, 'StoreSearchForm', $f, $a);
		return $customForm;//new Form($this,'StoreSearchForm',$fields,$actions);
	}
	
	public function doStoreSearch($data,$form){
		Session::set('SearchOption',$data['SearchOption']);
		Session::set('SuburbValue',$data['SuburbValue']);
		Session::set('SearchMethod',$data['SearchMethod']);
		return $this->redirect("/utilities/contact-us/stockists-store-locator/");
	}
}
?>