/**
 * StepUp Footwear - Complete Robust Apps Script Backend (With Admin Control Panel APIs)
 */

function setupShoesAppDatabase() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const schema = {
    "Users": ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"],
    "Shoes_Products": ["shoe_id", "title", "brand", "category", "size", "price", "stock_quantity", "image_url", "description"],
    "Cart": ["cart_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "price", "added_at"],
    "Wishlist": ["wishlist_id", "user_id", "shoe_id", "shoe_name", "price", "image_url", "added_at"],
    "Product_Reviews": ["review_id", "shoe_id", "user_id", "user_name", "rating", "review_text", "created_at"],
    "Orders": ["order_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "total_amount", "shipping_address", "order_status", "order_date"]
  };

  for (let sheetName in schema) {
    let sheet = ss.getSheetByName(sheetName);
    if (!sheet) sheet = ss.insertSheet(sheetName);
    const headers = schema[sheetName];
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold");
    sheet.getRange(1, 1, 1, headers.length).setBackground("#0F172A");
    sheet.getRange(1, 1, 1, headers.length).setFontColor("#00D2FF");
    sheet.setFrozenRows(1);
  }
}

function getOrCreateSheet(ss, sheetName, defaultHeaders) {
  let sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    if (defaultHeaders && defaultHeaders.length > 0) {
      sheet.getRange(1, 1, 1, defaultHeaders.length).setValues([defaultHeaders]);
      sheet.getRange(1, 1, 1, defaultHeaders.length).setFontWeight("bold");
      sheet.getRange(1, 1, 1, defaultHeaders.length).setBackground("#0F172A");
      sheet.getRange(1, 1, 1, defaultHeaders.length).setFontColor("#00D2FF");
      sheet.setFrozenRows(1);
    }
  }
  return sheet;
}

function extractParams(e) {
  let params = {};
  if (e && e.parameter) {
    for (let key in e.parameter) {
      params[key] = e.parameter[key];
    }
  }
  if (e && e.postData && e.postData.contents) {
    try {
      let body = JSON.parse(e.postData.contents);
      for (let k in body) {
        params[k] = body[k];
      }
    } catch (err) {}
  }
  return params;
}

function doGet(e) {
  return handleRequest(e);
}

function doPost(e) {
  return handleRequest(e);
}

function handleRequest(e) {
  const lock = LockService.getScriptLock();
  lock.tryLock(15000);

  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const params = extractParams(e);
    const action = (params.action || "").toString().trim().toLowerCase();

    if (!action) {
      return responseJSON({ status: "ERROR", message: "Action parameter missing!" });
    }

    // ==========================================
    // 1. AUTH & USERS
    // ==========================================

    // 1.1 LOGIN USER
    if (action === "loginuser") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const rows = sheet.getDataRange().getValues();
      const loginEmail = (params.email || "").toString().toLowerCase().trim();
      const loginPassword = (params.password || "").toString().trim();

      for (let i = 1; i < rows.length; i++) {
        const rowEmail = rows[i][2].toString().toLowerCase().trim();
        const rowPass = rows[i][5].toString().trim();

        if (rowEmail === loginEmail && rowPass === loginPassword) {
          return responseJSON({
            status: "SUCCESS",
            message: "Login successful",
            user: {
              user_id: rows[i][0],
              name: rows[i][1],
              email: rows[i][2],
              phone_number: rows[i][3].toString().replace(/^'/, ''),
              gender: rows[i][4],
              role: rows[i][6]
            }
          });
        }
      }
      return responseJSON({ status: "ERROR", message: "Invalid email or password!" });
    }

    // 1.2 REGISTER USER
    if (action === "registeruser") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const email = (params.email || "").toString().toLowerCase().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][2].toString().toLowerCase().trim() === email) {
          return responseJSON({ status: "ERROR", message: "Email already registered! Please login." });
        }
      }

      const rawPhone = (params.phone_number || "").toString().trim();
      const safePhone = rawPhone ? "'" + rawPhone : "";

      const userId = "USR_" + new Date().getTime();
      sheet.appendRow([
        userId,
        params.name || "",
        email,
        safePhone,
        params.gender || "Male",
        params.password || "",
        params.role || "Customer",
        new Date()
      ]);

      return responseJSON({
        status: "SUCCESS",
        message: "User registered successfully",
        userId: userId
      });
    }

    // 1.3 UPDATE USER PROFILE
    if (action === "updateprofile") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const rows = sheet.getDataRange().getValues();
      const userId = (params.user_id || "").toString().trim();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === userId) {
          if (params.name) sheet.getRange(i + 1, 2).setValue(params.name);
          if (params.phone_number) {
            const safePhone = "'" + params.phone_number.toString().trim();
            sheet.getRange(i + 1, 4).setValue(safePhone);
          }
          if (params.gender) sheet.getRange(i + 1, 5).setValue(params.gender);

          return responseJSON({
            status: "SUCCESS",
            message: "Profile updated successfully!",
            user: {
              user_id: rows[i][0],
              name: params.name || rows[i][1],
              email: rows[i][2],
              phone_number: (params.phone_number || rows[i][3]).toString().replace(/^'/, ''),
              gender: params.gender || rows[i][4],
              role: rows[i][6]
            }
          });
        }
      }
      return responseJSON({ status: "ERROR", message: "User not found!" });
    }

    // 1.4 CHANGE PASSWORD
    if (action === "changepassword") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const rows = sheet.getDataRange().getValues();
      const userId = (params.user_id || "").toString().trim();
      const oldPass = (params.old_password || "").toString().trim();
      const newPass = (params.new_password || "").toString().trim();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === userId) {
          const currentPass = rows[i][5].toString().trim();
          if (oldPass && currentPass !== oldPass) {
            return responseJSON({ status: "ERROR", message: "Old password is incorrect!" });
          }
          sheet.getRange(i + 1, 6).setValue(newPass);
          return responseJSON({ status: "SUCCESS", message: "Password updated successfully!" });
        }
      }
      return responseJSON({ status: "ERROR", message: "User not found!" });
    }

    // 1.5 GET ALL USERS (ADMIN)
    if (action === "getallusers") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const list = [];
      for (let i = 1; i < rows.length; i++) {
        let obj = {};
        headers.forEach((h, idx) => {
          let val = rows[i][idx];
          if (h === "phone_number" && val) val = val.toString().replace(/^'/, '');
          obj[h] = val;
        });
        list.push(obj);
      }
      return responseJSON({ status: "SUCCESS", data: list });
    }

    // 1.6 DELETE USER (ADMIN)
    if (action === "deleteuser") {
      const sheet = getOrCreateSheet(ss, "Users", ["user_id", "name", "email", "phone_number", "gender", "password", "role", "created_at"]);
      const userId = (params.user_id || "").toString().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === userId) {
          sheet.deleteRow(i + 1);
          return responseJSON({ status: "SUCCESS", message: "User deleted successfully from Google Sheet!" });
        }
      }
      return responseJSON({ status: "ERROR", message: "User not found!" });
    }

    // 1.7 SEND OTP (GMAIL)
    if (action === "sendotp") {
      const type = (params.type || "Email").toString().trim();
      const email = (params.email || "").toString().trim();
      const phone = (params.phone || "").toString().trim();
      const otp = (params.otp || "").toString().trim();
      const name = (params.name || "Valued Member").toString().trim();

      if (!otp) return responseJSON({ status: "ERROR", message: "OTP code missing!" });

      if (type.toLowerCase() === "email" && email) {
        try {
          const subject = "🔐 StepUp Footwear - Password Reset Verification OTP";
          const htmlBody = `
            <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0F1113; color: #ffffff; padding: 32px 24px; border-radius: 12px; max-width: 520px; margin: 0 auto; border: 1px solid #1F2937;">
              <div style="text-align: center; margin-bottom: 24px;">
                <span style="font-size: 24px; font-weight: 900; letter-spacing: 2px; color: #ffffff;">STEP<span style="color: #00D2FF;">UP</span></span>
                <p style="font-size: 11px; color: #9CA3AF; margin: 4px 0 0; letter-spacing: 1px; text-transform: uppercase;">Security Verification</p>
              </div>
              <p style="font-size: 15px; color: #E5E7EB; margin-bottom: 8px;">Hi <b>${name}</b>,</p>
              <p style="font-size: 13.5px; color: #9CA3AF; line-height: 1.5; margin-top: 0;">
                Your one-time password (OTP) for password reset is:
              </p>
              <div style="text-align: center; margin: 28px 0;">
                <div style="display: inline-block; background-color: #16191D; border: 2px solid #00D2FF; color: #00D2FF; font-size: 32px; font-weight: 900; letter-spacing: 8px; padding: 14px 32px; border-radius: 8px;">
                  ${otp}
                </div>
              </div>
              <p style="font-size: 12px; color: #9CA3AF; line-height: 1.4;">
                ⏱️ Valid for 10 minutes. Do not share with anyone.
              </p>
              <hr style="border: 0; border-top: 1px solid #1F2937; margin: 24px 0 16px;" />
              <p style="font-size: 11px; color: #6B7280; text-align: center; margin: 0;">© 2026 StepUp Footwear Inc.</p>
            </div>
          `;
          MailApp.sendEmail({ to: email, subject: subject, htmlBody: htmlBody });
          return responseJSON({ status: "SUCCESS", message: "OTP sent to " + email });
        } catch (mailErr) {
          return responseJSON({ status: "ERROR", message: mailErr.toString() });
        }
      }

      if (type.toLowerCase() === "phone" && phone) {
        return responseJSON({ status: "SUCCESS", message: "OTP sent to +91 " + phone });
      }
      return responseJSON({ status: "ERROR", message: "Target missing" });
    }

    // ==========================================
    // 2. PRODUCTS (Admin Catalog & Storefront)
    // ==========================================

    // 2.1 GET ALL PRODUCTS
    if (action === "getallproducts") {
      const sheet = getOrCreateSheet(ss, "Shoes_Products", ["shoe_id", "title", "brand", "category", "size", "price", "stock_quantity", "image_url", "description"]);
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const list = [];
      for (let i = 1; i < rows.length; i++) {
        let obj = {};
        headers.forEach((h, idx) => { obj[h] = rows[i][idx]; });
        list.push(obj);
      }
      return responseJSON({ status: "SUCCESS", data: list });
    }

    // 2.2 SAVE PRODUCT (Add & Edit)
    if (action === "saveproduct") {
      const sheet = getOrCreateSheet(ss, "Shoes_Products", ["shoe_id", "title", "brand", "category", "size", "price", "stock_quantity", "image_url", "description"]);
      const shoeId = (params.shoe_id || "").toString().trim() !== "" ? params.shoe_id.toString().trim() : ("PROD_" + new Date().getTime());
      const rows = sheet.getDataRange().getValues();
      let foundIndex = -1;

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === shoeId) {
          foundIndex = i + 1;
          break;
        }
      }

      const rowData = [
        shoeId,
        params.title || "",
        params.brand || "StepUp",
        params.category || "Sneakers",
        params.size || "7,8,9,10",
        Number(params.price) || 0,
        Number(params.stock_quantity) || 10,
        params.image_url || "assets/Puma.jpg",
        params.description || ""
      ];

      if (foundIndex > 0) {
        sheet.getRange(foundIndex, 1, 1, rowData.length).setValues([rowData]);
        return responseJSON({ status: "SUCCESS", message: "Product updated in Sheet successfully!", shoe_id: shoeId });
      } else {
        sheet.appendRow(rowData);
        return responseJSON({ status: "SUCCESS", message: "New product created in Sheet!", shoe_id: shoeId });
      }
    }

    // 2.3 DELETE PRODUCT
    if (action === "deleteproduct") {
      const sheet = getOrCreateSheet(ss, "Shoes_Products", ["shoe_id", "title", "brand", "category", "size", "price", "stock_quantity", "image_url", "description"]);
      const shoeId = (params.shoe_id || "").toString().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === shoeId) {
          sheet.deleteRow(i + 1);
          return responseJSON({ status: "SUCCESS", message: "Product deleted from Sheet!" });
        }
      }
      return responseJSON({ status: "ERROR", message: "Product not found!" });
    }

    // ==========================================
    // 3. CART & WISHLIST
    // ==========================================

    // 3.1 ADD TO CART
    if (action === "addtocart") {
      const sheet = getOrCreateSheet(ss, "Cart", ["cart_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "price", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const shoeId = (params.shoe_id || "").toString().trim();
      const size = (params.size || "7").toString().trim();
      const qty = Number(params.quantity) || 1;
      const price = Number(params.price) || 0;
      const shoeName = (params.shoe_name || "").toString().trim();

      const rows = sheet.getDataRange().getValues();
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][1].toString().trim() === userId &&
            rows[i][2].toString().trim() === shoeId &&
            rows[i][4].toString().trim() === size) {
          const currentQty = Number(rows[i][5]) || 1;
          sheet.getRange(i + 1, 6).setValue(currentQty + qty);
          return responseJSON({ status: "SUCCESS", message: "Cart quantity updated!" });
        }
      }

      const cartId = "CRT_" + new Date().getTime();
      sheet.appendRow([cartId, userId, shoeId, shoeName, size, qty, price, new Date()]);
      return responseJSON({ status: "SUCCESS", message: "Item added to cart!", cart_id: cartId });
    }

    // 3.2 REMOVE FROM CART
    if (action === "removefromcart") {
      const sheet = getOrCreateSheet(ss, "Cart", ["cart_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "price", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const shoeId = (params.shoe_id || "").toString().trim();
      const size = (params.size || "").toString().trim();

      const rows = sheet.getDataRange().getValues();
      for (let i = 1; i < rows.length; i++) {
        const matchesUser = rows[i][1].toString().trim() === userId;
        const matchesShoe = rows[i][2].toString().trim() === shoeId;
        const matchesSize = size === "" || rows[i][4].toString().trim() === size;

        if (matchesUser && matchesShoe && matchesSize) {
          sheet.deleteRow(i + 1);
          return responseJSON({ status: "SUCCESS", message: "Item removed from cart!" });
        }
      }
      return responseJSON({ status: "SUCCESS", message: "Item removed!" });
    }

    // 3.3 GET CART
    if (action === "getcart") {
      const sheet = getOrCreateSheet(ss, "Cart", ["cart_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "price", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const items = [];
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][1].toString().trim() === userId) {
          let obj = {};
          headers.forEach((h, idx) => { obj[h] = rows[i][idx]; });
          items.push(obj);
        }
      }
      return responseJSON({ status: "SUCCESS", data: items });
    }

    // 3.4 ADD TO WISHLIST
    if (action === "addtowishlist") {
      const sheet = getOrCreateSheet(ss, "Wishlist", ["wishlist_id", "user_id", "shoe_id", "shoe_name", "price", "image_url", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const shoeId = (params.shoe_id || "").toString().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][1].toString().trim() === userId && rows[i][2].toString().trim() === shoeId) {
          return responseJSON({ status: "SUCCESS", message: "Item already in wishlist!" });
        }
      }

      const wishlistId = "WSH_" + new Date().getTime();
      sheet.appendRow([wishlistId, userId, shoeId, params.shoe_name || "", Number(params.price) || 0, params.image_url || "", new Date()]);
      return responseJSON({ status: "SUCCESS", message: "Added to wishlist!", wishlist_id: wishlistId });
    }

    // 3.5 REMOVE FROM WISHLIST
    if (action === "removefromwishlist") {
      const sheet = getOrCreateSheet(ss, "Wishlist", ["wishlist_id", "user_id", "shoe_id", "shoe_name", "price", "image_url", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const shoeId = (params.shoe_id || "").toString().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][1].toString().trim() === userId && rows[i][2].toString().trim() === shoeId) {
          sheet.deleteRow(i + 1);
          return responseJSON({ status: "SUCCESS", message: "Item removed!" });
        }
      }
      return responseJSON({ status: "SUCCESS", message: "Item removed!" });
    }

    // 3.6 GET WISHLIST
    if (action === "getwishlist") {
      const sheet = getOrCreateSheet(ss, "Wishlist", ["wishlist_id", "user_id", "shoe_id", "shoe_name", "price", "image_url", "added_at"]);
      const userId = (params.user_id || "GUEST").toString().trim();
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const items = [];
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][1].toString().trim() === userId) {
          let obj = {};
          headers.forEach((h, idx) => { obj[h] = rows[i][idx]; });
          items.push(obj);
        }
      }
      return responseJSON({ status: "SUCCESS", data: items });
    }

    // ==========================================
    // 4. ORDERS & PAYMENTS (Storefront & Admin)
    // ==========================================

    // 4.1 PLACE ORDER
    if (action === "placeorder") {
      const sheet = getOrCreateSheet(ss, "Orders", ["order_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "total_amount", "shipping_address", "order_status", "order_date"]);
      const orderId = (params.order_id || ("ORD_" + new Date().getTime())).toString().trim();
      const userId = (params.user_id || "GUEST").toString().trim();
      const shoeId = (params.shoe_id || "").toString().trim();
      const shoeName = (params.shoe_name || "").toString().trim();
      const size = (params.size || "").toString().trim();
      const quantity = Number(params.quantity) || 1;
      const totalAmount = Number(params.total_amount) || 0;
      const shippingAddress = (params.shipping_address || "").toString().trim();
      const orderStatus = (params.order_status || "Confirmed").toString().trim();

      sheet.appendRow([
        orderId,
        userId,
        shoeId,
        shoeName,
        size,
        quantity,
        totalAmount,
        shippingAddress,
        orderStatus,
        new Date()
      ]);

      // Remove ordered item from user's cart if exists
      const cartSheet = getOrCreateSheet(ss, "Cart", ["cart_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "price", "added_at"]);
      const cartRows = cartSheet.getDataRange().getValues();
      for (let i = cartRows.length - 1; i >= 1; i--) {
        if (cartRows[i][1].toString().trim() === userId) {
          cartSheet.deleteRow(i + 1);
        }
      }

      return responseJSON({
        status: "SUCCESS",
        message: "Order placed successfully!",
        order_id: orderId
      });
    }

    // 4.2 GET ALL ORDERS (ADMIN)
    if (action === "getallorders") {
      const sheet = getOrCreateSheet(ss, "Orders", ["order_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "total_amount", "shipping_address", "order_status", "order_date"]);
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const list = [];
      for (let i = 1; i < rows.length; i++) {
        let obj = {};
        headers.forEach((h, idx) => { obj[h] = rows[i][idx]; });
        list.push(obj);
      }
      return responseJSON({ status: "SUCCESS", data: list });
    }

    // 4.3 UPDATE ORDER STATUS (ADMIN: Pending, Accepted, Dispatched, Delivered, Cancelled)
    if (action === "updateorderstatus") {
      const sheet = getOrCreateSheet(ss, "Orders", ["order_id", "user_id", "shoe_id", "shoe_name", "size", "quantity", "total_amount", "shipping_address", "order_status", "order_date"]);
      const orderId = (params.order_id || "").toString().trim();
      const newStatus = (params.order_status || "").toString().trim();
      const rows = sheet.getDataRange().getValues();

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][0].toString().trim() === orderId) {
          sheet.getRange(i + 1, 9).setValue(newStatus); // 9th Column is order_status
          return responseJSON({
            status: "SUCCESS",
            message: "Order status updated to " + newStatus + " in Google Sheet!"
          });
        }
      }
      return responseJSON({ status: "ERROR", message: "Order ID not found!" });
    }

    // ==========================================
    // 5. REVIEWS & FEEDBACK
    // ==========================================

    // 5.1 ADD REVIEW
    if (action === "addreview") {
      const sheet = getOrCreateSheet(ss, "Product_Reviews", ["review_id", "shoe_id", "user_id", "user_name", "rating", "review_text", "created_at"]);
      const reviewId = "REV_" + new Date().getTime();
      sheet.appendRow([
        reviewId,
        (params.shoe_id || "").toString().trim(),
        (params.user_id || "GUEST").toString().trim(),
        (params.user_name || "Customer").toString().trim(),
        Number(params.rating) || 5,
        (params.review_text || "").toString().trim(),
        new Date()
      ]);
      return responseJSON({ status: "SUCCESS", message: "Review added successfully!" });
    }

    // 5.2 GET REVIEWS
    if (action === "getreviews" || action === "getallreviews") {
      const sheet = getOrCreateSheet(ss, "Product_Reviews", ["review_id", "shoe_id", "user_id", "user_name", "rating", "review_text", "created_at"]);
      const shoeId = (params.shoe_id || "").toString().trim();
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return responseJSON({ status: "SUCCESS", data: [] });

      const headers = rows[0];
      const list = [];
      for (let i = 1; i < rows.length; i++) {
        if (shoeId === "" || rows[i][1].toString().trim() === shoeId) {
          let obj = {};
          headers.forEach((h, idx) => { obj[h] = rows[i][idx]; });
          list.push(obj);
        }
      }
      return responseJSON({ status: "SUCCESS", data: list });
    }

    return responseJSON({ status: "ERROR", message: "Invalid action: " + action });

  } catch (err) {
    return responseJSON({ status: "ERROR", message: err.toString() });
  } finally {
    lock.releaseLock();
  }
}

function responseJSON(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}