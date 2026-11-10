import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  PaymentModel,
  formatVnpayDate,
  sortObject,
  createHmacSha512,
  verifyVnpayChecksum,
} from './payment.model.js';

test('formatVnpayDate: trả về chuỗi 14 chữ số chuẩn YYYYMMDDHHmmss', () => {
  const dateStr = formatVnpayDate();
  assert.equal(typeof dateStr, 'string');
  assert.equal(dateStr.length, 14);
  assert.match(dateStr, /^[0-9]{14}$/);
});

test('sortObject: sắp xếp thuộc tính theo thứ tự alphabet và mã hóa URL', () => {
  const input = {
    vnp_Version: '2.1.0',
    vnp_Amount: 1000000,
    vnp_Command: 'pay',
    vnp_OrderInfo: 'Thanh toan don hang',
  };
  const sorted = sortObject(input);
  const keys = Object.keys(sorted);
  assert.deepEqual(keys, ['vnp_Amount', 'vnp_Command', 'vnp_OrderInfo', 'vnp_Version']);
  assert.equal(sorted.vnp_OrderInfo, 'Thanh+toan+don+hang');
});

test('verifyVnpayChecksum: kiểm tra tính toàn vẹn chữ ký HmacSHA512', () => {
  const secretKey = 'TEST_SECRET_KEY';
  const params: Record<string, any> = {
    vnp_Amount: '1000000',
    vnp_Command: 'pay',
    vnp_OrderInfo: 'Thanh toan don hang',
    vnp_ResponseCode: '00',
    vnp_TmnCode: 'MENLY001',
    vnp_TxnRef: 'ORD_TEST_01',
  };

  const sorted = sortObject(params);
  const signData = Object.keys(sorted)
    .map((k) => `${k}=${sorted[k]}`)
    .join('&');
  const validHash = createHmacSha512(signData, secretKey);

  // Kiểm tra với hash hợp lệ
  const validCheck = verifyVnpayChecksum({ ...params, vnp_SecureHash: validHash }, secretKey);
  assert.equal(validCheck.isValid, true);

  // Kiểm tra khi hash bị giả mạo / sai
  const invalidCheck = verifyVnpayChecksum({ ...params, vnp_SecureHash: 'tampered_hash_value' }, secretKey);
  assert.equal(invalidCheck.isValid, false);
});

test('PaymentModel.createPaymentUrl: tạo URL thanh toán chứa đầy đủ tham số và chữ ký', async () => {
  const model = new PaymentModel();
  const result = await model.createPaymentUrl({
    orderCode: 'ORD_DEMO_99',
    amount: 150000,
    orderInfo: 'Thanh toan ao so mi Menly',
  });

  assert.ok(result.paymentUrl);
  assert.ok(result.txnRef.startsWith('ORD_DEMO_99_'));
  assert.equal(result.amount, 150000);

  const url = new URL(result.paymentUrl);
  assert.equal(url.searchParams.get('vnp_Amount'), '15000000'); // 150000 * 100
  assert.equal(url.searchParams.get('vnp_Command'), 'pay');
  assert.ok(url.searchParams.get('vnp_SecureHash'));
});

test('PaymentModel.processIpn: từ chối khi chữ ký (checksum) không hợp lệ', async () => {
  const model = new PaymentModel();
  const result = await model.processIpn({
    vnp_TxnRef: 'TXN_TEST',
    vnp_Amount: '10000000',
    vnp_ResponseCode: '00',
    vnp_SecureHash: 'invalid_checksum',
  });

  assert.equal(result.RspCode, '97');
  assert.equal(result.Message, 'Invalid Checksum');
});

