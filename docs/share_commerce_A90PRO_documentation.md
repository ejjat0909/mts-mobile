# Share Commerce A90PRO Documentation

## Documentation Index

| Main Articles                                                                   | Integration                                              | Request Response                            |
| ------------------------------------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------- |
| [Appendix 1 - Transaction Types](#appendix-1---transaction-types)               | [Web API](#web-api-integration)                          | [Terminate Session](#terminate-session)     |
| [Appendix 2 - Response Codes](#appendix-2---response-codes)                     | [Web Socket](#websocket-integration)                     | [Enquiry](#enquiry)                         |
| [Appendix 3 - Response Object Example](#appendix-3---response-object-example)   | [Cable Connect (USB / RS232)](#cable-connect-usb--rs232) | [Sale (Card)](#sale-card)                   |
| [Appendix 4 - Payment Code Types](#appendix-4---payment-code-types-generate-qr) | [AppToApp / DeepLink](#apptoapp--deeplink-integration)   | [Sale (Scan QR)](#sale-scan-qr)             |
|                                                                                 |                                                          | [Sale (Generate QR)](#sale-generate-qr)     |
|                                                                                 |                                                          | [Void (Card)](#void-card)                   |
|                                                                                 |                                                          | [Void (QR)](#void-qr)                       |
|                                                                                 |                                                          | [Settlement](#settlement)                   |
|                                                                                 |                                                          | [Sale (Preauth)](#sale-preauth)             |
|                                                                                 |                                                          | [Sale (Sale Complete)](#sale-complete)      |
|                                                                                 |                                                          | [Void (Preauth)](#void-preauth)             |
|                                                                                 |                                                          | [Void (Sale Complete)](#void-sale-complete) |

---

## Appendix 1 - Transaction Types

| Transaction Type  | Value |
| ----------------- | ----- |
| Terminate Session | 0     |
| Enquiry           | 1     |
| Sale              | 2     |
| Void              | 3     |
| Settlement        | 4     |

---

## Appendix 2 - Response Codes

| Code   | Description                                       |
| ------ | ------------------------------------------------- |
| 00     | Approved                                          |
| 01     | Refer To Issuer                                   |
| 02     | Refer To Issuer, special condition                |
| 03     | Invalid Merchant ID                               |
| 04     | Pick Up Card                                      |
| 05     | Do Not Honour                                     |
| 06     | Error                                             |
| 07     | Pick Up Card, special condition                   |
| 08     | Check Signature/Id or Honor with ID               |
| 10     | Partial Approval                                  |
| 11     | VIP Approval                                      |
| 12     | Invalid Transaction                               |
| 13     | Invalid Amount                                    |
| 14     | Invalid Card No                                   |
| 15     | Invalid Issuer                                    |
| 16     | Approved to update track 3 (Reserved)             |
| 17     | Customer Cancellation (Reversal only)             |
| 19     | Re-enter Transaction                              |
| 21     | No Transactions                                   |
| 22     | Related Transaction Error; Suspected Malfunction  |
| 24     | Invalid Currency Code                             |
| 25     | Terminated/Inactive card                          |
| 30     | Message Format Error                              |
| 31     | Bank ID Not Found                                 |
| 32     | Partial Reversal                                  |
| 38     | PIN Try Limit Exceeded                            |
| 41     | Card Reported Lost                                |
| 43     | Stolen Card                                       |
| 44     | PIN Change Require                                |
| 45     | Card Not Activated For Use                        |
| 51     | Insufficient Fund                                 |
| 52     | No Checking Account                               |
| 53     | No Savings Account                                |
| 54     | Expired Card                                      |
| 55     | Invalid PIN                                       |
| 56     | Invalid Card                                      |
| 57     | Transaction Not Permitted to Cardholder           |
| 58     | Transaction Not Permitted to Terminal             |
| 59     | Suspected Fraud                                   |
| 61     | Over Limit                                        |
| 62     | Restricted Card                                   |
| 63     | Security Violation                                |
| 64     | Transaction does not fulfill AML requirement      |
| 65     | Exceeds Withdrawal Count Limit                    |
| 70     | Contact Card Issuer                               |
| 71     | PIN not changed                                   |
| 75     | PIN Tries Exceeded                                |
| 76     | Invalid Description Code                          |
| 77     | Reconcile Error                                   |
| 78     | Invalid Trace/TMK Reference No                    |
| 79     | Batch Already Open                                |
| 80     | Invalid Batch No                                  |
| 82     | CVV Validation Error                              |
| 85     | Batch Not Found                                   |
| 86     | PIN Validation Not Possible                       |
| 87     | Purchase Amount Only, No Cash Back Allowed        |
| 88     | Cryptographic Failure, Call Issuer                |
| 89     | Invalid Terminal ID                               |
| 91     | Issuer/Switch Inoperative                         |
| 92     | Destination Cannot Be Found for Routing           |
| 93     | Transaction cannot be completed; violation of law |
| 94     | Duplicate Transaction                             |
| 95     | Total Mismatch                                    |
| 96     | System Malfunction/Error                          |
| 98     | Issuer Response Not Receive by UnionPay           |
| 99     | Declined                                          |
| B1     | Do Not Allow Attempt                              |
| C1     | Channel not found                                 |
| C2     | Invalid Terminal                                  |
| C3     | Inactive Terminal                                 |
| C4     | Routing Not Allowed                               |
| E1     | MAC Failed                                        |
| E2     | Channel Error                                     |
| E3     | Requesting NII not registered                     |
| E4     | Invalid Data in Request                           |
| F3     | User Cancel the Transaction                       |
| G1     | Host Timeout                                      |
| G2     | HSM Error Found                                   |
| SHC001 | Invalid Parameter                                 |
| SHC002 | Auto Settlement Is Running                        |
| SHC003 | No Batch To Settle                                |
| SHC004 | Settlement Fail                                   |
| SHC005 | User Cancel The Transaction                       |
| SHC006 | Timeout                                           |
| SHC007 | Terminal System Error                             |
| SHC008 | Transaction Not Found                             |
| SHC009 | Payment Session Terminated                        |
| ZT     | Transaction Reversal                              |
| ZU     | Timeout                                           |
| ZV     | Empty Secure Key                                  |
| ZW     | Card Declined Transaction                         |
| ZX     | Please Insert or Try Another Card                 |
| ZY     | Please Insert Card                                |
| ZZ     | Card Not Supported                                |

---

## Appendix 3 - Response Object Example

| Response Object                      | Example                                                                                   |
| ------------------------------------ | ----------------------------------------------------------------------------------------- |
| ResponseCode (String)                | 00                                                                                        |
| ResponseDescription (String)         | (00)Approved                                                                              |
| TransactionType (String)             | 1                                                                                         |
| TransactionAmount (String)           | 1.00                                                                                      |
| TransactionMID (String)              | 123456789012345                                                                           |
| TransactionTID (String)              | 12345678                                                                                  |
| TransactionSTN (String)              | 000099                                                                                    |
| TransactionInvoice (String)          | 000099                                                                                    |
| TransactionBatchNo (String)          | 000001                                                                                    |
| TransactionApplicationLabel (String) | VISA CREDIT                                                                               |
| TransactionCardNo (String)           | 423400**\*\***2381                                                                        |
| TransactionEntryType (String)        | Contactless                                                                               |
| TransactionARQC (String)             | 3FDEF7F00A937559                                                                          |
| TransactionTVR (String)              | 0000000000                                                                                |
| TransactionAID (String)              | A0000000031010                                                                            |
| TransactionCVM (String)              | 1F0302                                                                                    |
| TransactionTSI (String)              | -                                                                                         |
| TransactionApprovalCode (String)     | 222876                                                                                    |
| TransactionRRN (String)              | 001231000010                                                                              |
| TransactionSchemeID (String)         | 11                                                                                        |
| TransactionDateTime (String)         | 2023-06-23 09:57:28                                                                       |
| TransactionEPP (Json String)         | `{"Acquirer":"", "Tenure":"", "TotalAmt":"1.00", "MonthlyAmt":"1.00", "FinalAmt":"1.00"}` |
| PosReference (String)                | 1234567890                                                                                |

---

## Appendix 4 - Payment Code Types (Generate QR)

| Payment Code  |
| ------------- |
| QR_ALIPAYPLUS |
| QR_BOOST      |
| QR_DUITNOW    |
| QR_FAVEPAY    |
| QR_GRABPAY    |
| QR_MCASH      |
| QR_NETSPAY    |
| QR_REDPAY     |
| QR_UNIONPAY   |

---

## Web API Integration

Kindly refer command below for Web API interaction.

### Configuration Details

| Item           | Description                                                                                                                                               |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setup Details  | The HTTP communication protocol was used to communicate between terminal and third party's device.                                                        |
| URL            | The terminal URL is `http://[terminal_ip_address]:8890`. The IP address can be obtained from the terminal and changes according to network configuration. |
| Listener       | The listener only active at main page. If the terminal is at a different page, the terminal won't listen to incoming messages.                            |
| Message Format | POST request method is used for this communication.                                                                                                       |
| Header         | `Content-Type: application/json`                                                                                                                          |

### Request Example

```json
{
  "TransactionType": "1",
  "TransactionAmount": "100"
}
```

### Response Example

```json
{
  "ResponseCode": "00",
  "ResponseDescription": "Approved",
  "TransactionType": "1",
  "TransactionAmount": "1.00",
  "TransactionMID": "000000000000001",
  "TransactionTID": "00000001",
  "TransactionSTN": "000001",
  "TransactionRRN": "123456789012",
  "TransactionBatchNo": "000001",
  "TransactionApplicationLabel": "Visa Credit",
  "TransactionCardNo": "412345******9999",
  "TransactionEntryType": "wave",
  "TransactionARQC": "8989898989",
  "TransactionTVR": "0000000000",
  "TransactionAID": "00000000003101",
  "TransactionCVM": "000000",
  "TransactionTSI": "00",
  "TransactionApprovalCode": "123456",
  "TransactionInvoice": "000001",
  "TransactionSchemeID": "01",
  "TransactionDateTime": "20220501110023"
}
```

### CURL Example

```bash
curl --location --request POST 'http://115.132.150.54:8890' \
  --header 'Content-Type: application/json' \
  --data-raw '{"TransactionType":"1","TransactionAmount":"1.00"}'
```

---

## WebSocket Integration

Kindly refer command below for WebSocket interaction.

### Configuration Details

| Item           | Description                                                                                                                                             |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setup Details  | The WebSocket communication protocol is used to communicate between terminal and third party's device.                                                  |
| URL            | The terminal URL is `ws://[terminal_ip_address]:8080`. The IP address can be obtained from the terminal and changes according to network configuration. |
| Listener       | The listener only active at main page. If the terminal is at a different page, the terminal won't listen to incoming messages.                          |
| Error Recovery | WebSocket will auto recover previous disconnected response when third party's devices restore the connection.                                           |
| Message Format | POST request method is used for this communication.                                                                                                     |

### Request Example

```json
{
  "TransactionType": "1",
  "TransactionAmount": "100"
}
```

### Response Example

```json
{
  "ResponseCode": "00",
  "ResponseDescription": "Approved",
  "TransactionType": "1",
  "TransactionAmount": "1.00",
  "TransactionMID": "000000000000001",
  "TransactionTID": "00000001",
  "TransactionSTN": "000001",
  "TransactionRRN": "123456789012",
  "TransactionBatchNo": "000001",
  "TransactionApplicationLabel": "Visa Credit",
  "TransactionCardNo": "412345******9999",
  "TransactionEntryType": "wave",
  "TransactionARQC": "8989898989",
  "TransactionTVR": "0000000000",
  "TransactionAID": "00000000003101",
  "TransactionCVM": "000000",
  "TransactionTSI": "00",
  "TransactionApprovalCode": "123456",
  "TransactionInvoice": "000001",
  "TransactionSchemeID": "01",
  "TransactionDateTime": "20220501110023"
}
```

---

## Cable Connect (USB / RS232)

Kindly refer command below for Cable Connect integration.

### Configuration Details

| Item           | Description                                                            |
| -------------- | ---------------------------------------------------------------------- |
| Setup Details  | Different cable connection using different type of cable and extension |
| Message Format | JSON messages are used for the request and response                    |
| Technical Info | **BaudRate**: 115200, **DataBits**: 8, **Parity**: 0, **StopBits**: 1  |

### Request Example

```json
{
  "TransactionType": "1",
  "TransactionAmount": "100"
}
```

### Response Example

```json
{
  "ResponseCode": "00",
  "ResponseDescription": "Approved",
  "TransactionType": "1",
  "TransactionAmount": "1.00",
  "TransactionMID": "000000000000001",
  "TransactionTID": "00000001",
  "TransactionSTN": "000001",
  "TransactionRRN": "123456789012",
  "TransactionBatchNo": "000001",
  "TransactionApplicationLabel": "Visa Credit",
  "TransactionCardNo": "412345******9999",
  "TransactionEntryType": "wave",
  "TransactionARQC": "8989898989",
  "TransactionTVR": "0000000000",
  "TransactionAID": "00000000003101",
  "TransactionCVM": "000000",
  "TransactionTSI": "00",
  "TransactionApprovalCode": "123456",
  "TransactionInvoice": "000001",
  "TransactionSchemeID": "01",
  "TransactionDateTime": "20220501110023"
}
```

---

## AppToApp / DeepLink Integration

Kindly refer command below for AppToApp interaction.

### Request Example

```java
HashMap<String,String> map = new HashMap<>();

map.put("Package_Name","[POS Application PackageName]");
map.put("Activity_Name","[POS Class going to receive the response]");
map.put("TransactionType", "2");
map.put(PaymentChannel, "CARD");
map.put("TransactionAmount", "100");

Intent intent = getPackageManager().getLaunchIntentForPackage("[Get PackageName from ShareCommerce]");
intent.setAction(Intent.ACTION_SENDTO);
intent.setClassName("[Get PackageName from ShareCommerce]", "com.sc.sharenfc.kotlin.activity.TransactionReceiver");
intent.setType("text/plain");
intent.putExtra("txn_map",map);
startActivity(intent);
```

### Response Example

```java
HashMap<String,String> map = new HashMap<>();

txn_map.put("ResponseCode",respCode);
txn_map.put("ResponseDescription",desc);
txn_map.put("TransactionType", txnType);
txn_map.put("TransactionAmount",txnAmt);
txn_map.put("TransactionMID",mid);
txn_map.put("TransactionTID",tid);
txn_map.put("TransactionSTN",stan);
txn_map.put("TransactionRRN",rrn);
txn_map.put("TransactionBatchNo",batchNo);
txn_map.put("TransactionApplicationLabel",appLabel);
txn_map.put("TransactionCardNo",cardMask);
txn_map.put("TransactionEntryType",entryMode);
txn_map.put("TransactionARQC",arqc);
txn_map.put("TransactionTVR",tvr);
txn_map.put("TransactionAID",aid);
txn_map.put("TransactionCVM",cvm);
txn_map.put("TransactionTSI",tsi);
txn_map.put("TransactionApprovalCode",apprCode);
txn_map.put("TransactionInvoice",invNo);
txn_map.put("TransactionSchemeID",schemeId);
txn_map.put("TransactionDateTime",txnDt);

Intent intent_transmit = getPackageManager().getLaunchIntentForPackage("[POS Application PackageName]");
intent_transmit.setAction(Intent.ACTION_SEND);
intent_transmit.setClassName("[POS Application PackageName]", "[POS Application ActivityName]");
intent_transmit.putExtra("txn_map",map);
startActivity(intent_transmit);
```

---

## Transaction Type Details

### Terminate Session

| Request                       | Response                |
| ----------------------------- | ----------------------- |
| **TransactionType** - 0 (Int) | **ResponseCode**        |
|                               | **ResponseDescription** |
|                               | **TransactionType**     |

---

### Enquiry

| Request                       | Response                        |
| ----------------------------- | ------------------------------- |
| **TransactionType** - 1 (Int) | **ResponseCode**                |
| **PosReference** (String)     | **ResponseDescription**         |
|                               | **TransactionType**             |
|                               | **TransactionAmount**           |
|                               | **TransactionMID**              |
|                               | **TransactionTID**              |
|                               | **TransactionSTN**              |
|                               | **TransactionRRN**              |
|                               | **TransactionBatchNo**          |
|                               | **TransactionApplicationLabel** |
|                               | **TransactionCardNo**           |
|                               | **TransactionEntryType**        |
|                               | **TransactionARQC**             |
|                               | **TransactionTVR**              |
|                               | **TransactionAID**              |
|                               | **TransactionCVM**              |
|                               | **TransactionTSI**              |
|                               | **TransactionApprovalCode**     |
|                               | **TransactionInvoice**          |
|                               | **TransactionSchemeID**         |
|                               | **TransactionDateTime**         |

---

### Sale (Card)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 2 (Int)               | **ResponseCode**                |
| **TransactionAmount** (Int)                 | **ResponseDescription**         |
| **PaymentChannel** - 'CARD' (String)        | **TransactionType**             |
| PosReference (String)                       | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                  | **TransactionMID**              |
| OrderingItem (String)                       | **TransactionTID**              |
| OrderingItemImage (String) (Base64 Image)   | **TransactionSTN**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionRRN**              |
| Package_Name (Mandatory for AppToApp only)  | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

#### OrderingItem JSON Structure

The `OrderingItem` is a Base64 encoded string representation of the following JSON object:

```json
{
  "TableNo": "String",
  "OrderDateTime": "String",
  "InvoiceNo": "String",
  "OrderNo": "String",
  "NoOfGuest": "Int",
  "CashierName": "String",
  "ItemList": [
    {
      "Quantity": "Int",
      "ItemDescription": "String",
      "PricePerQty": "Double",
      "Total": "Double",
      "SubItemList": [
        {
          "Quantity": "Int",
          "ItemDescription": "String",
          "PricePerQty": "Double",
          "Total": "Double"
        }
      ]
    }
  ],
  "SummaryList": [
    {
      "Item": "String",
      "Amt": "Double"
    }
  ],
  "TotalAmt": "Double"
}
```

---

### Sale (Scan QR)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 2 (Int)               | **ResponseCode**                |
| **TransactionAmount** (Int)                 | **ResponseDescription**         |
| **PaymentChannel** - 'SCAN' (String)        | **TransactionType**             |
| CameraFacing (Int)                          | **TransactionAmount**           |
| PosReference (String)                       | **TransactionMID**              |
| AcknowledgeCountdown (Int)                  | **TransactionTID**              |
| OrderingItem (String)                       | **TransactionSTN**              |
| OrderingItemImage (String) (Base64 Image)   | **TransactionRRN**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionBatchNo**          |
| Package_Name (Mandatory for AppToApp only)  | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

#### OrderingItem JSON Structure

The `OrderingItem` is a Base64 encoded string representation of the following JSON object:

```json
{
  "TableNo": "String",
  "OrderDateTime": "String",
  "InvoiceNo": "String",
  "NoOfGuest": "Int",
  "CashierName": "String",
  "ItemList": [
    {
      "Quantity": "Int",
      "ItemDescription": "String",
      "PricePerQty": "Double",
      "Total": "Double",
      "SubItemList": [
        {
          "Quantity": "Int",
          "ItemDescription": "String",
          "PricePerQty": "Double",
          "Total": "Double"
        }
      ]
    }
  ],
  "SummaryList": [
    {
      "Item": "String",
      "Amt": "Double"
    }
  ],
  "TotalAmt": "Double"
}
```

---

### Sale (Generate QR)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 2 (Int)               | **ResponseCode**                |
| **TransactionAmount** (Int)                 | **ResponseDescription**         |
| **PaymentChannel** - 'QR' (String)          | **TransactionType**             |
| **PaymentCode** (String)                    | **TransactionAmount**           |
| PosReference (String)                       | **TransactionMID**              |
| AcknowledgeCountdown (Int)                  | **TransactionTID**              |
| OrderingItem (String)                       | **TransactionSTN**              |
| OrderingItemImage (String) (Base64 Image)   | **TransactionRRN**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionBatchNo**          |
| Package_Name (Mandatory for AppToApp only)  | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

#### OrderingItem JSON Structure

The `OrderingItem` is a Base64 encoded string representation of the following JSON object:

```json
{
  "TableNo": "String",
  "OrderDateTime": "String",
  "InvoiceNo": "String",
  "NoOfGuest": "Int",
  "CashierName": "String",
  "ItemList": [
    {
      "Quantity": "Int",
      "ItemDescription": "String",
      "PricePerQty": "Double",
      "Total": "Double",
      "SubItemList": [
        {
          "Quantity": "Int",
          "ItemDescription": "String",
          "PricePerQty": "Double",
          "Total": "Double"
        }
      ]
    }
  ],
  "SummaryList": [
    {
      "Item": "String",
      "Amt": "Double"
    }
  ],
  "TotalAmt": "Double"
}
```

---

### Void (Card)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 3 (Int)               | **ResponseCode**                |
| **TransactionInvoice** (String)             | **ResponseDescription**         |
| **PaymentChannel** - 'CARD' (String)        | **TransactionType**             |
| PosReference (String)                       | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                  | **TransactionMID**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionTID**              |
| Package_Name (Mandatory for AppToApp only)  | **TransactionSTN**              |
|                                             | **TransactionRRN**              |
|                                             | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

---

### Void (QR)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 3 (Int)               | **ResponseCode**                |
| **TransactionInvoice** (String)             | **ResponseDescription**         |
| **PaymentChannel** - 'QR' (String)          | **TransactionType**             |
| PosReference (String)                       | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                  | **TransactionMID**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionTID**              |
| Package_Name (Mandatory for AppToApp only)  | **TransactionSTN**              |
|                                             | **TransactionRRN**              |
|                                             | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

---

### Settlement

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 4 (Int)               | **ResponseCode**                |
| **PaymentChannel** (String)                 | **ResponseDescription**         |
| Activity_Name (Mandatory for AppToApp only) | **TransactionType**             |
| Package_Name (Mandatory for AppToApp only)  | **TransactionAmount**           |
|                                             | **TransactionMID**              |
|                                             | **TransactionTID**              |
|                                             | **TransactionSTN**              |
|                                             | **TransactionRRN**              |
|                                             | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

---

### Sale (Preauth)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 5 (Int)               | **ResponseCode**                |
| **TransactionAmount** (Int)                 | **ResponseDescription**         |
| **PreAuthType** - 'PREAUTH' (String)        | **TransactionType**             |
| PosReference (String)                       | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                  | **TransactionMID**              |
| OrderingItem (String)                       | **TransactionTID**              |
| OrderingItemImage (String) (Base64 Image)   | **TransactionSTN**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionRRN**              |
| Package_Name (Mandatory for AppToApp only)  | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

#### OrderingItem JSON Structure

The `OrderingItem` is a Base64 encoded string representation of the following JSON object:

```json
{
  "TableNo": "String",
  "OrderDateTime": "String",
  "InvoiceNo": "String",
  "OrderNo": "String",
  "NoOfGuest": "Int",
  "CashierName": "String",
  "ItemList": [
    {
      "Quantity": "Int",
      "ItemDescription": "String",
      "PricePerQty": "Double",
      "Total": "Double",
      "SubItemList": [
        {
          "Quantity": "Int",
          "ItemDescription": "String",
          "PricePerQty": "Double",
          "Total": "Double"
        }
      ]
    }
  ],
  "SummaryList": [
    {
      "Item": "String",
      "Amt": "Double"
    }
  ],
  "TotalAmt": "Double"
}
```

---

### Sale (Sale Complete)

| Request                                      | Response                        |
| -------------------------------------------- | ------------------------------- |
| **TransactionType** - 5 (Int)                | **ResponseCode**                |
| **TransactionAmount** (Int)                  | **ResponseDescription**         |
| **PreAuthType** - 'PREAUTHCOMPLETE' (String) | **TransactionType**             |
| **TransactionApprovalCode** (String)         | **TransactionAmount**           |
| **TransactionRRN** (String)                  | **TransactionMID**              |
| **TransactionInvoice** (String)              | **TransactionTID**              |
| PosReference (String)                        | **TransactionSTN**              |
| AcknowledgeCountdown (Int)                   | **TransactionRRN**              |
| OrderingItem (String)                        | **TransactionBatchNo**          |
| OrderingItemImage (String) (Base64 Image)    | **TransactionApplicationLabel** |
| Activity_Name (Mandatory for AppToApp only)  | **TransactionCardNo**           |
| Package_Name (Mandatory for AppToApp only)   | **TransactionEntryType**        |
|                                              | **TransactionARQC**             |
|                                              | **TransactionTVR**              |
|                                              | **TransactionAID**              |
|                                              | **TransactionCVM**              |
|                                              | **TransactionTSI**              |
|                                              | **TransactionApprovalCode**     |
|                                              | **TransactionInvoice**          |
|                                              | **TransactionSchemeID**         |
|                                              | **TransactionDateTime**         |

#### OrderingItem JSON Structure

The `OrderingItem` is a Base64 encoded string representation of the following JSON object:

```json
{
  "TableNo": "String",
  "OrderDateTime": "String",
  "InvoiceNo": "String",
  "OrderNo": "String",
  "NoOfGuest": "Int",
  "CashierName": "String",
  "ItemList": [
    {
      "Quantity": "Int",
      "ItemDescription": "String",
      "PricePerQty": "Double",
      "Total": "Double",
      "SubItemList": [
        {
          "Quantity": "Int",
          "ItemDescription": "String",
          "PricePerQty": "Double",
          "Total": "Double"
        }
      ]
    }
  ],
  "SummaryList": [
    {
      "Item": "String",
      "Amt": "Double"
    }
  ],
  "TotalAmt": "Double"
}
```

---

### Void (Preauth)

| Request                                     | Response                        |
| ------------------------------------------- | ------------------------------- |
| **TransactionType** - 5 (Int)               | **ResponseCode**                |
| **TransactionInvoice** (String)             | **ResponseDescription**         |
| **PreAuthType** - 'VOIDPREAUTH' (String)    | **TransactionType**             |
| PosReference (String)                       | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                  | **TransactionMID**              |
| Activity_Name (Mandatory for AppToApp only) | **TransactionTID**              |
| Package_Name (Mandatory for AppToApp only)  | **TransactionSTN**              |
|                                             | **TransactionRRN**              |
|                                             | **TransactionBatchNo**          |
|                                             | **TransactionApplicationLabel** |
|                                             | **TransactionCardNo**           |
|                                             | **TransactionEntryType**        |
|                                             | **TransactionARQC**             |
|                                             | **TransactionTVR**              |
|                                             | **TransactionAID**              |
|                                             | **TransactionCVM**              |
|                                             | **TransactionTSI**              |
|                                             | **TransactionApprovalCode**     |
|                                             | **TransactionInvoice**          |
|                                             | **TransactionSchemeID**         |
|                                             | **TransactionDateTime**         |

---

### Void (Sale Complete)

| Request                                          | Response                        |
| ------------------------------------------------ | ------------------------------- |
| **TransactionType** - 5 (Int)                    | **ResponseCode**                |
| **TransactionInvoice** (String)                  | **ResponseDescription**         |
| **PreAuthType** - 'VOIDPREAUTHCOMPLETE' (String) | **TransactionType**             |
| PosReference (String)                            | **TransactionAmount**           |
| AcknowledgeCountdown (Int)                       | **TransactionMID**              |
| Activity_Name (Mandatory for AppToApp only)      | **TransactionTID**              |
| Package_Name (Mandatory for AppToApp only)       | **TransactionSTN**              |
|                                                  | **TransactionRRN**              |
|                                                  | **TransactionBatchNo**          |
|                                                  | **TransactionApplicationLabel** |
|                                                  | **TransactionCardNo**           |
|                                                  | **TransactionEntryType**        |
|                                                  | **TransactionARQC**             |
|                                                  | **TransactionTVR**              |
|                                                  | **TransactionAID**              |
|                                                  | **TransactionCVM**              |
|                                                  | **TransactionTSI**              |
|                                                  | **TransactionApprovalCode**     |
|                                                  | **TransactionInvoice**          |
|                                                  | **TransactionSchemeID**         |
|                                                  | **TransactionDateTime**         |
