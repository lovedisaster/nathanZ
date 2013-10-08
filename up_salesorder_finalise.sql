--------------------------------- 
-- up_salesorder_finalise.sql  
---------------------------------

---------------------------------------------------------------------------------------
-- The up_salesorder_finalise stored procedure is used to update a pending sales order
-- (inserted using the SalesOrderSubmit web service) to mark it as approved or to 
-- cancel the sales order. The action performed will depend on the success or failure 
-- of payment of the order. This stored procedure does NOT deal with payment information.
-- Payment information is applied using a separate stored procedure.
--
-- This stored procedure can only be applied to sales orders which are neither approved
-- or cancelled. Running this stored procedure against a sales order which is already 
-- approved or cancelled will result in an error being raised.
--
-- NOTE: Transaction scoping is not included in this stored procedure, The scoping of 
-- transactions will be handled at the Web Service level as additional stored procedures
-- may be required to be called within the same transaction scope.
--
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Maintenance Log
---------------------------------------------------------------------------------------
-- Task   | Who | Date     | Comments
----------+-----+----------+---------------RDWS 1.5.7.1 -------------------------------
-- 018490 | YFZ | 20111116 | Updated to allow the salesordertender_id to be specified
--                         | in the input. This prevents nested transaction scoping
--                         | issues from occurring.
----------+-----+----------+-----------------------------------------------------------
-- 014934 | MEH | 20100111 | Created.
----------+-----+----------+-----------------------------------------------------------

EXEC sp_addmessage @msgnum = 57818, @severity = 16, 
   @msgtext = N'Unable to identify the sales order. The sales order code %s could not be found.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57819, @severity = 16, 
   @msgtext = N'Unable to verify the identity of sales order %s. The specified customer_id %s does not match the customer_id of the sales order.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57820, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the order has already been %s.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57821, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the action (%s) is not a valid action. Valid actions are: Approve and Cancel.',
	@replace = 'replace'

-- TODO: Register these errors.

EXEC sp_addmessage @msgnum = 57822, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the tendertype_mnemonic (%s) does not exist or is inactive.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57823, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the payment amount was not specified.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57824, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the payment amount (%s) was less than zero.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57825, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the payment reference number was not specified.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57826, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the currency code (%s) does not exist or is inactive.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57827, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the head office datacentre code could not be found.',
	@replace = 'replace'

EXEC sp_addmessage @msgnum = 57828, @severity = 16, 
   @msgtext = N'Unable to finalise sales order %s, the transaction could not be committed to the database.',
	@replace = 'replace'

GO

IF (EXISTS (SELECT * FROM dbo.sysobjects WHERE ([name] = 'up_salesorder_finalise') AND (type = 'P') AND (uid = USER_ID('dbo'))))
	DROP PROCEDURE dbo.up_salesorder_finalise
GO

CREATE PROCEDURE dbo.up_salesorder_finalise
    @salesorder_code         VARCHAR(16), -- The sales order to finalise.
    @user_code               VARCHAR(12), -- The user code of the user performing the update.
    @action                   VARCHAR(8), -- The finalisation action (either 'Approve' or 'Cancel').
    @tendertype_mnemonic     VARCHAR(12), -- The mnemonic of the tendertype that the payment will be associated with.
    @tender_amount         NUMERIC(19,4), -- The amount of the payment (must not be negative).
    @currency_code           VARCHAR(12), -- The currency code of the currency that the tender_amount is specified in.
    @tender_reference_number VARCHAR(32), -- The payment reference (eg: PayPal Transaction ID).
    @tender_approval_code    VARCHAR(12), -- The code returned by the payment provider.
    @tender_comment          VARCHAR(255), -- Any comments returned by the payment provider.
    @salesordertender_id     VARCHAR(12) = NULL -- The ID of the new salesordertender record (Required in new process).
AS
-------------------------------------------------------------------------
-- RDWS Version RDWSVersionNumber
-------------------------------------------------------------------------

DECLARE @approved_ind        CHAR(1),
        @cancelled_ind       CHAR(1),
        @order_code          VARCHAR(12),
        @so_customer_code    VARCHAR(12),
        @tendertype_id       VARCHAR(12),
        @ho_datacentre_code  VARCHAR(4),
        @error_number        INT,
        @negative_price_text VARCHAR(12)

-- check that the sales order exists, if the customer_id is specified, it must also match.
SELECT @order_code = salesorder_code,
       @approved_ind = approved_ind,
       @cancelled_ind = cancelled_ind
  FROM salesorder WITH(NOLOCK)
 WHERE salesorder_code = ISNULL(@salesorder_code,'')

-- Check that the order exists.
IF ISNULL(@order_code, '') = ''
BEGIN
    RAISERROR(57818, 16, 4, @salesorder_code)
    RETURN -1
END

-- Check that transaction has not already been approved.
IF @approved_ind = 'Y'
BEGIN
    RAISERROR(57820, 16, 1, @order_code, 'approved') 
    RETURN -1
END

-- Check that transaction has not already been cancelled.
IF @cancelled_ind = 'Y'
BEGIN
    RAISERROR(57820, 16, 2, @order_code, 'cancelled')
    RETURN -1
END
 
-- Set the approved and cancelled flags depending on the action.
IF ISNULL(@action, '') = 'Approve'
BEGIN
    SELECT @approved_ind = 'Y', @cancelled_ind = 'N'

    -- Check that payment information is valid.
    IF @tender_amount IS NULL
    BEGIN
        RAISERROR(57823, 16, 4, @order_code)
        RETURN -1
    END
    ELSE IF @tender_amount < 0.0
    BEGIN
        SELECT @negative_price_text = CAST(@tender_amount AS VARCHAR(12))
        RAISERROR(57824, 16, 4, @order_code, @negative_price_text)
        RETURN -1
    END

    IF ISNULL(@tender_reference_number,'') = ''
    BEGIN
        RAISERROR(57825, 16, 4, @order_code)
        RETURN -1
    END

    IF NOT EXISTS (SELECT 1 FROM currency WITH(NOLOCK) WHERE currency_code = @currency_code AND ISNULL(active_ind,'N') = 'Y')
    BEGIN
        RAISERROR(57826, 16, 4, @order_code, @currency_code)
        RETURN -1
    END
END
ELSE IF ISNULL(@action, '') = 'Cancel'
BEGIN
    SELECT @approved_ind = 'N', @cancelled_ind = 'Y'
END
ELSE
BEGIN
    -- Error, invalid action.
    RAISERROR(57821, 16, 4, @order_code, @action)
    RETURN -1
END

-- If we have tender information, record it regardless
-- of whether the order was approved or not.
IF ISNULL(@tender_reference_number, '') <> '' 
BEGIN
    SELECT @tendertype_id = tendertype_id
      FROM tendertype WITH(NOLOCK)
     WHERE tendertype_mnemonic = @tendertype_mnemonic
       AND ISNULL(active_ind,'N') = 'Y'

    IF ISNULL(@tendertype_id,'') = ''
    BEGIN
        RAISERROR(57822, 16, 4, @order_code, @tendertype_mnemonic)
        RETURN -1
    END

	-- If newly generated ID is not supplied, we need to generate one.
	IF ISNULL(@salesordertender_id,'') = ''
    BEGIN
    SELECT @ho_datacentre_code = datacentre_code
		  FROM datacentre WITH(NOLOCK)
     WHERE ISNULL(headoffice_ind,'N') = 'Y'

    IF ISNULL(@ho_datacentre_code,'') = ''
    BEGIN
        RAISERROR(57827, 16, 4, @order_code)
        RETURN -1
    END

    -- All input ok, create a new salesordertender_id
    EXEC up_nextid
         @datacentre_code = @ho_datacentre_code,
         @nextid = @salesordertender_id OUTPUT
    END
END

SELECT @error_number = 0

BEGIN TRANSACTION

    INSERT salesordertender
    (
        salesordertender_id,
        salesorder_code,
        tendertype_id,
        tender_value,
        currency_code,
        tender_reference_number,
        tender_approval_code,
        tender_comment,
        insert_date_time,
        insert_user
    )
    VALUES
    (
        @salesordertender_id,
        @salesorder_code,
        @tendertype_id,
        @tender_amount,
        @currency_code,
        @tender_reference_number,
        @tender_approval_code,
        @tender_comment,
        GETDATE(),
        @user_code
    )

    SELECT @error_number = @@ERROR

    IF @error_number = 0
    BEGIN
		-- Update the sales order record to the new status, customer reference number and update date time.
		UPDATE so
		   SET so.approved_ind = @approved_ind,
			   so.cancelled_ind = @cancelled_ind,
			   so.update_user = @user_code,
			   so.update_date_time = GETDATE()
		  FROM salesorder so
		 WHERE so.salesorder_code = @order_code
    END

IF @error_number <> 0
BEGIN
    ROLLBACK TRANSACTION
    RAISERROR(57828, 16, 4, @order_code)
    RETURN -1
END
ELSE
BEGIN
    COMMIT TRANSACTION
END

GO