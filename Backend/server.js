import "dotenv/config";

import express from "express";
import cors from "cors";
import multer from "multer";
import { createClient } from "@supabase/supabase-js";

const app = express();
const PORT = Number(process.env.PORT || 3000);

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY =
  process.env.SUPABASE_PUBLISHABLE_KEY;
const SUPABASE_SERVICE_ROLE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY;

if (
  !SUPABASE_URL ||
  !SUPABASE_PUBLISHABLE_KEY ||
  !SUPABASE_SERVICE_ROLE_KEY
) {
  console.error(
    "============================================"
  );
  console.error(
    "NYAYASETU BACKEND CONFIGURATION ERROR"
  );
  console.error(
    "Required Supabase environment variables are missing."
  );
  console.error(
    "Check backend/.env"
  );
  console.error(
    "============================================"
  );

  process.exit(1);
}

const supabase =
  createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false
      }
    }
  );

const supabaseAdmin =
  createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false
      }
    }
  );

const allowedOrigins =
  new Set([
    "http://127.0.0.1:5500",
    "http://localhost:5500",
    "http://127.0.0.1:3000",
    "http://localhost:3000",

    ...(process.env.FRONTEND_URL || "")
      .split(",")
      .map(
        value =>
          value.trim()
      )
      .filter(Boolean)
  ]);

app.use(
  cors({
    origin(
      origin,
      callback
    ) {
      if (
        !origin ||
        allowedOrigins.has(
          origin
        )
      ) {
        return callback(
          null,
          true
        );
      }

      return callback(
        new Error(
          "Origin is not allowed by NyayaSetu CORS policy."
        )
      );
    },

    methods: [
      "GET",
      "POST",
      "OPTIONS"
    ],

    allowedHeaders: [
      "Content-Type",
      "Authorization"
    ]
  })
);

app.use(
  express.json({
    limit: "2mb"
  })
);

const allowedLawyerPhotoTypes =
  new Set([
    "image/jpeg",
    "image/png",
    "image/webp"
  ]);

const lawyerPhotoUpload =
  multer({
    storage:
      multer.memoryStorage(),

    limits: {
      fileSize:
        5 * 1024 * 1024
    },

    fileFilter(
      req,
      file,
      callback
    ) {
      if (
        !allowedLawyerPhotoTypes.has(
          file.mimetype
        )
      ) {
        return callback(
          new Error(
            "Only JPG, JPEG, PNG or WEBP profile photos are allowed."
          )
        );
      }

      callback(
        null,
        true
      );
    }
  });

function normalizeText(
  value
) {
  return String(
    value || ""
  ).trim();
}

function normalizeEmail(
  value
) {
  return String(
    value || ""
  )
    .trim()
    .toLowerCase();
}

function validEmail(
  value
) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    .test(
      value
    );
}

function validIndianPhone(
  value
) {
  return /^[6-9]\d{9}$/
    .test(
      value
    );
}

function safeNumber(
  value
) {
  const n =
    Number(
      value
    );

  return Number.isFinite(
    n
  )
    ? n
    : NaN;
}

function getPhotoExtension(
  mimeType
) {
  if (
    mimeType ===
    "image/png"
  ) {
    return "png";
  }

  if (
    mimeType ===
    "image/webp"
  ) {
    return "webp";
  }

  return "jpg";
}

function parseLanguages(
  rawValue
) {
  if (
    Array.isArray(
      rawValue
    )
  ) {
    return rawValue
      .map(
        normalizeText
      )
      .filter(Boolean);
  }

  const rawText =
    String(
      rawValue || ""
    ).trim();

  if (
    !rawText
  ) {
    return [];
  }

  try {
    const parsed =
      JSON.parse(
        rawText
      );

    if (
      Array.isArray(
        parsed
      )
    ) {
      return parsed
        .map(
          normalizeText
        )
        .filter(Boolean);
    }
  }
  catch (_) {
  }

  return rawText
    .split(",")
    .map(
      normalizeText
    )
    .filter(Boolean);
}

async function findAuthUserByEmail(
  email
) {
  const normalizedEmail =
    normalizeEmail(
      email
    );

  let page =
    1;

  const perPage =
    1000;

  while (
    true
  ) {
    const {
      data,
      error
    } =
      await supabaseAdmin
        .auth
        .admin
        .listUsers({
          page,
          perPage
        });

    if (
      error
    ) {
      throw error;
    }

    const users =
      data?.users || [];

    const match =
      users.find(
        user =>
          normalizeEmail(
            user.email
          )
          ===
          normalizedEmail
      );

    if (
      match
    ) {
      return match;
    }

    if (
      users.length <
      perPage
    ) {
      break;
    }

    page +=
      1;
  }

  return null;
}

async function cleanupNewAuthUser(
  userId
) {
  if (
    !userId
  ) {
    return;
  }

  try {
    const {
      error
    } =
      await supabaseAdmin
        .auth
        .admin
        .deleteUser(
          userId
        );

    if (
      error
    ) {
      console.error(
        "Auth cleanup error:",
        error
      );
    }
  }
  catch (
    error
  ) {
    console.error(
      "Unexpected Auth cleanup error:",
      error
    );
  }
}

async function cleanupLawyerPhoto(
  photoPath
) {
  if (
    !photoPath
  ) {
    return;
  }

  try {
    const {
      error
    } =
      await supabaseAdmin
        .storage
        .from(
          "lawyer-profile-photos"
        )
        .remove([
          photoPath
        ]);

    if (
      error
    ) {
      console.error(
        "Photo cleanup error:",
        error
      );
    }
  }
  catch (
    error
  ) {
    console.error(
      "Unexpected Photo cleanup error:",
      error
    );
  }
}

async function requireAdminFromRequest(
  req
) {
  const authorization =
    String(
      req.headers.authorization || ""
    );

  const match =
    authorization.match(
      /^Bearer\s+(.+)$/i
    );

  if (
    !match
  ) {
    return {
      ok: false,
      status: 401,
      message:
        "Admin authentication is required."
    };
  }

  const accessToken =
    match[1];

  const {
    data,
    error
  } =
    await supabaseAdmin
      .auth
      .getUser(
        accessToken
      );

  if (
    error ||
    !data?.user
  ) {
    return {
      ok: false,
      status: 401,
      message:
        "The Admin session is invalid or expired."
    };
  }

  const {
    data: profile,
    error: profileError
  } =
    await supabaseAdmin
      .from(
        "profiles"
      )
      .select(
        "id, role, is_active"
      )
      .eq(
        "id",
        data.user.id
      )
      .maybeSingle();

  if (
    profileError ||
    !profile ||
    String(
      profile.role || ""
    ).toLowerCase()
      !==
      "admin" ||
    profile.is_active ===
      false
  ) {
    return {
      ok: false,
      status: 403,
      message:
        "Admin authorization is required."
    };
  }

  return {
    ok: true,
    user:
      data.user,
    profile
  };
}

function pdfSafeText(
  value
) {
  return String(
    value ?? ""
  )
    .normalize(
      "NFKD"
    )
    .replace(
      /[^\x20-\x7E]/g,
      "?"
    )
    .replace(
      /\\/g,
      "\\\\"
    )
    .replace(
      /\(/g,
      "\\("
    )
    .replace(
      /\)/g,
      "\\)"
    );
}

function receiptMoney(
  value
) {
  return Number(
    value || 0
  )
    .toFixed(
      2
    );
}

function receiptDateTime(
  value
) {
  if (
    !value
  ) {
    return "-";
  }

  const date =
    new Date(
      value
    );

  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return String(
      value
    );
  }

  return date
    .toLocaleString(
      "en-IN",
      {
        timeZone:
          "Asia/Kolkata",

        day:
          "2-digit",

        month:
          "short",

        year:
          "numeric",

        hour:
          "2-digit",

        minute:
          "2-digit",

        hour12:
          true
      }
    );
}

function receiptDate(
  value
) {
  if (
    !value
  ) {
    return "-";
  }

  const date =
    new Date(
      `${String(value)}T00:00:00`
    );

  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return String(
      value
    );
  }

  return date
    .toLocaleDateString(
      "en-IN",
      {
        day:
          "2-digit",

        month:
          "long",

        year:
          "numeric"
      }
    );
}

function receiptCategory(
  value
) {
  const labels = {
    criminal:
      "Criminal Law",

    family:
      "Family Law",

    property:
      "Property Law",

    corporate:
      "Corporate Law",

    civil:
      "Civil Law",

    financial:
      "Financial Law"
  };

  const key =
    String(
      value || ""
    )
      .trim()
      .toLowerCase();

  return labels[
    key
  ]
  ||
  String(
    value ||
    "Legal Consultation"
  );
}

function buildSimpleReceiptPdf(
  receiptData
) {
  const lines = [
    {
      text:
        "NYAYASETU",
      size:
        22,
      bold:
        true,
      gap:
        30
    },

    {
      text:
        "LEGAL DISPUTE MANAGEMENT PLATFORM",
      size:
        10,
      gap:
        22
    },

    {
      text:
        "PAYMENT RECEIPT",
      size:
        18,
      bold:
        true,
      gap:
        32
    },

    {
      text:
        `Receipt Number: ${receiptData.receiptNumber}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Transaction ID: ${receiptData.transactionId}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Payment Date & Time: ${receiptData.paymentDateTime}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Payment Status: ${receiptData.paymentStatus}`,
      size:
        11,
      gap:
        28
    },

    {
      text:
        "CONSULTATION DETAILS",
      size:
        13,
      bold:
        true,
      gap:
        22
    },

    {
      text:
        `Client: ${receiptData.clientName}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Lawyer: ${receiptData.lawyerName}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Legal Category: ${receiptData.legalCategory}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Appointment Date: ${receiptData.appointmentDate}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Appointment Time: ${receiptData.appointmentTime}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Consultation Mode: ${receiptData.consultationMode}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Payment Method: ${receiptData.paymentMethod}`,
      size:
        11,
      gap:
        28
    },

    {
      text:
        "PAYMENT SUMMARY",
      size:
        13,
      bold:
        true,
      gap:
        22
    },

    {
      text:
        `Consultation Fee: INR ${receiptData.consultationFee}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Platform Fee (10%): INR ${receiptData.platformFee}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `Amount Payable to Lawyer (90%): INR ${receiptData.lawyerAmount}`,
      size:
        11,
      gap:
        18
    },

    {
      text:
        `TOTAL AMOUNT PAID: INR ${receiptData.totalAmount}`,
      size:
        12,
      bold:
        true,
      gap:
        30
    },

    {
      text:
        "Payment is held by NyayaSetu. Lawyer payout is released according to the consultation workflow.",
      size:
        9,
      gap:
        20
    },

    {
      text:
        "This is a computer-generated receipt and does not require a signature.",
      size:
        9,
      gap:
        18
    },

    {
      text:
        "NyayaSetu | Secure Documents | Transparent Payments | Verified Lawyers",
      size:
        9,
      gap:
        18
    }
  ];

  let y =
    790;

  let content =
    "BT\n";

  for (
    const line
    of
    lines
  ) {
    const fontName =
      line.bold
        ?
        "F2"
        :
        "F1";

    const fontSize =
      Number(
        line.size || 11
      );

    content +=
      `/${fontName} ${fontSize} Tf\n`;

    content +=
      `1 0 0 1 55 ${y} Tm\n`;

    content +=
      `(${pdfSafeText(line.text)}) Tj\n`;

    y -=
      Number(
        line.gap || 18
      );
  }

  content +=
    "ET";

  const objects =
    [];

  objects[1] =
    "<< /Type /Catalog /Pages 2 0 R >>";

  objects[2] =
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>";

  objects[3] =
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>";

  objects[4] =
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>";

  objects[5] =
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>";

  objects[6] =
    `<< /Length ${Buffer.byteLength(content, "utf8")} >>\nstream\n${content}\nendstream`;

  let pdf =
    "%PDF-1.4\n";

  const offsets =
    [0];

  for (
    let index = 1;
    index <= 6;
    index += 1
  ) {
    offsets[index] =
      Buffer.byteLength(
        pdf,
        "utf8"
      );

    pdf +=
      `${index} 0 obj\n${objects[index]}\nendobj\n`;
  }

  const xrefOffset =
    Buffer.byteLength(
      pdf,
      "utf8"
    );

  pdf +=
    "xref\n";

  pdf +=
    "0 7\n";

  pdf +=
    "0000000000 65535 f \n";

  for (
    let index = 1;
    index <= 6;
    index += 1
  ) {
    pdf +=
      `${String(offsets[index]).padStart(10, "0")} 00000 n \n`;
  }

  pdf +=
    "trailer\n";

  pdf +=
    "<< /Size 7 /Root 1 0 R >>\n";

  pdf +=
    "startxref\n";

  pdf +=
    `${xrefOffset}\n`;

  pdf +=
    "%%EOF";

  return Buffer.from(
    pdf,
    "utf8"
  );
}

async function generateReceiptPdfForPayment(
  paymentId
) {
  const {
    data:
      payment,
    error:
      paymentError
  } =
    await supabaseAdmin
      .from(
        "payments"
      )
      .select(
        "id, payment_code, appointment_id, client_id, lawyer_id, total_amount, platform_fee, lawyer_amount, upi_transaction_id, payment_method, payment_status, verified_at, submitted_at, created_at"
      )
      .eq(
        "id",
        paymentId
      )
      .maybeSingle();

  if (
    paymentError
  ) {
    throw paymentError;
  }

  if (
    !payment
  ) {
    throw new Error(
      "Payment record was not found."
    );
  }

  if (
    String(
      payment.payment_status || ""
    )
      .toUpperCase()
    !==
    "PAYMENT_VERIFIED"
  ) {
    throw new Error(
      "Receipt PDF can only be generated for a verified payment."
    );
  }

  const {
    data:
      appointment,
    error:
      appointmentError
  } =
    await supabaseAdmin
      .from(
        "appointments"
      )
      .select(
        "id, client_id, lawyer_id, directory_profile_id, public_lawyer_name, public_lawyer_image, legal_category, appointment_date, appointment_time, consultation_mode, problem_description, consultation_fee, status"
      )
      .eq(
        "id",
        payment.appointment_id
      )
      .maybeSingle();

  if (
    appointmentError
  ) {
    throw appointmentError;
  }

  if (
    !appointment
  ) {
    throw new Error(
      "Appointment record was not found."
    );
  }

  const {
    data:
      receipt,
    error:
      receiptError
  } =
    await supabaseAdmin
      .from(
        "receipts"
      )
      .select(
        "id, receipt_number, payment_id, appointment_id, client_id, lawyer_id, public_lawyer_name, total_amount, platform_fee, lawyer_amount, payment_method, payment_status, pdf_path, issued_at"
      )
      .eq(
        "payment_id",
        payment.id
      )
      .maybeSingle();

  if (
    receiptError
  ) {
    throw receiptError;
  }

  if (
    !receipt
  ) {
    throw new Error(
      "Receipt record has not been created yet."
    );
  }

  if (
    receipt.pdf_path
  ) {
    return {
      receiptId:
        receipt.id,

      receiptNumber:
        receipt.receipt_number,

      pdfPath:
        receipt.pdf_path,

      alreadyExists:
        true
    };
  }

  const {
    data:
      clientProfile,
    error:
      clientProfileError
  } =
    await supabaseAdmin
      .from(
        "profiles"
      )
      .select(
        "id, full_name"
      )
      .eq(
        "id",
        payment.client_id
      )
      .maybeSingle();

  if (
    clientProfileError
  ) {
    console.warn(
      "Receipt Client profile lookup error:",
      clientProfileError
    );
  }

  const selectedPublicLawyerName =
    String(
      appointment.public_lawyer_name
      ||
      receipt.public_lawyer_name
      ||
      "Lawyer"
    )
      .trim();

  const receiptPayload = {
    receiptNumber:
      receipt.receipt_number
      ||
      receipt.id,

    transactionId:
      payment.upi_transaction_id
      ||
      payment.payment_code
      ||
      payment.id,

    paymentDateTime:
      receiptDateTime(
        payment.verified_at
        ||
        receipt.issued_at
        ||
        payment.submitted_at
        ||
        payment.created_at
      ),

    paymentStatus:
      String(
        receipt.payment_status
        ||
        payment.payment_status
        ||
        "PAYMENT_VERIFIED"
      )
        .replace(
          /_/g,
          " "
        ),

    clientName:
      String(
        clientProfile?.full_name
        ||
        "NyayaSetu Client"
      )
        .trim(),

    lawyerName:
      selectedPublicLawyerName,

    legalCategory:
      receiptCategory(
        appointment.legal_category
      ),

    appointmentDate:
      receiptDate(
        appointment.appointment_date
      ),

    appointmentTime:
      appointment.appointment_time
      ||
      "-",

    consultationMode:
      appointment.consultation_mode
      ||
      "-",

    paymentMethod:
      payment.payment_method
      ||
      receipt.payment_method
      ||
      "Google Pay / UPI",

    consultationFee:
      receiptMoney(
        appointment.consultation_fee
      ),

    platformFee:
      receiptMoney(
        receipt.platform_fee
        ??
        payment.platform_fee
      ),

    lawyerAmount:
      receiptMoney(
        receipt.lawyer_amount
        ??
        payment.lawyer_amount
      ),

    totalAmount:
      receiptMoney(
        receipt.total_amount
        ??
        payment.total_amount
      )
  };

  const pdfBuffer =
    buildSimpleReceiptPdf(
      receiptPayload
    );

  const safeReceiptNumber =
    String(
      receipt.receipt_number
      ||
      receipt.id
    )
      .replace(
        /[^a-zA-Z0-9_-]/g,
        "_"
      );

  const pdfPath =
    `${payment.client_id}/${safeReceiptNumber}.pdf`;

  const {
    error:
      uploadError
  } =
    await supabaseAdmin
      .storage
      .from(
        "receipts"
      )
      .upload(
        pdfPath,
        pdfBuffer,
        {
          contentType:
            "application/pdf",

          upsert:
            true
        }
      );

  if (
    uploadError
  ) {
    throw uploadError;
  }

  const {
    data:
      updatedReceipt,
    error:
      updateReceiptError
  } =
    await supabaseAdmin
      .from(
        "receipts"
      )
      .update({
        public_lawyer_name:
          selectedPublicLawyerName,

        pdf_path:
          pdfPath
      })
      .eq(
        "id",
        receipt.id
      )
      .select(
        "id, receipt_number, payment_id, appointment_id, client_id, lawyer_id, public_lawyer_name, total_amount, platform_fee, lawyer_amount, payment_method, payment_status, pdf_path, issued_at"
      )
      .single();

  if (
    updateReceiptError
  ) {
    try {
      await supabaseAdmin
        .storage
        .from(
          "receipts"
        )
        .remove([
          pdfPath
        ]);
    }
    catch (
      cleanupError
    ) {
      console.warn(
        "Receipt PDF cleanup error:",
        cleanupError
      );
    }

    throw updateReceiptError;
  }

  return {
    receiptId:
      updatedReceipt.id,

    receiptNumber:
      updatedReceipt.receipt_number,

    publicLawyerName:
      updatedReceipt.public_lawyer_name,

    pdfPath:
      updatedReceipt.pdf_path,

    alreadyExists:
      false
  };
}

app.post(
  "/api/admin/payments/:paymentId/generate-receipt-pdf",

  async (
    req,
    res
  ) => {
    try {
      const adminCheck =
        await requireAdminFromRequest(
          req
        );

      if (
        !adminCheck.ok
      ) {
        return res
          .status(
            adminCheck.status
          )
          .json({
            success:
              false,

            message:
              adminCheck.message
          });
      }

      const paymentId =
        normalizeText(
          req.params.paymentId
        );

      if (
        !paymentId
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Payment ID is required."
          });
      }

      const result =
        await generateReceiptPdfForPayment(
          paymentId
        );

      return res
        .status(
          200
        )
        .json({
          success:
            true,

          message:
            result.alreadyExists
              ?
              "Receipt PDF already exists."
              :
              "Receipt PDF generated successfully.",

          receipt:
            result
        });
    }
    catch (
      error
    ) {
      console.error(
        "Receipt PDF generation error:",
        error
      );

      return res
        .status(
          500
        )
        .json({
          success:
            false,

          message:
            error?.message
            ||
            "Receipt PDF could not be generated."
        });
    }
  }
);

app.get(
  "/",

  (
    req,
    res
  ) => {
    return res
      .status(
        200
      )
      .json({
        success:
          true,

        service:
          "NyayaSetu Backend",

        status:
          "running"
      });
  }
);

app.get(
  "/api/health",

  (
    req,
    res
  ) => {
    return res.json({
      success:
        true,

      service:
        "NyayaSetu Backend",

      status:
        "running"
    });
  }
);

app.post(
  "/api/register/client",

  async (
    req,
    res
  ) => {
    let newlyCreatedUserId =
      null;

    try {
      const fullName =
        normalizeText(
          req.body.fullName
        );

      const email =
        normalizeEmail(
          req.body.email
        );

      const password =
        String(
          req.body.password || ""
        );

      const phone =
        normalizeText(
          req.body.phone
        );

      const city =
        normalizeText(
          req.body.city
        );

      const state =
        normalizeText(
          req.body.state
        );

      if (
        !fullName
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Full name is required."
          });
      }

      if (
        !validEmail(
          email
        )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid email address."
          });
      }

      if (
        password.length <
        6
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Password must contain at least 6 characters."
          });
      }

      if (
        phone &&
        !validIndianPhone(
          phone
        )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid 10-digit Indian mobile number."
          });
      }

      const existingAuthUser =
        await findAuthUserByEmail(
          email
        );

      if (
        existingAuthUser
      ) {
        return res
          .status(
            409
          )
          .json({
            success:
              false,

            code:
              "ACCOUNT_ALREADY_EXISTS",

            message:
              "An account already exists with this email address. Please login instead."
          });
      }

      const {
        data:
          signupData,
        error:
          signupError
      } =
        await supabase
          .auth
          .signUp({
            email,
            password,

            options: {
              data: {
                role:
                  "client",

                full_name:
                  fullName,

                phone,
                city,
                state
              }
            }
          });

      if (
        signupError
      ) {
        throw signupError;
      }

      if (
        !signupData?.user?.id
      ) {
        throw new Error(
          "Client account could not be created."
        );
      }

      newlyCreatedUserId =
        signupData.user.id;

      const {
        error:
          profileError
      } =
        await supabaseAdmin
          .from(
            "profiles"
          )
          .upsert(
            {
              id:
                newlyCreatedUserId,

              role:
                "client",

              full_name:
                fullName,

              phone:
                phone || null,

              city:
                city || null,

              state:
                state || null,

              is_active:
                true
            },

            {
              onConflict:
                "id"
            }
          );

      if (
        profileError
      ) {
        throw profileError;
      }

      newlyCreatedUserId =
        null;

      return res
        .status(
          201
        )
        .json({
          success:
            true,

          message:
            "Client account created successfully. Please verify your email before login."
        });
    }
    catch (
      error
    ) {
      console.error(
        "Client registration error:",
        error
      );

      if (
        newlyCreatedUserId
      ) {
        await cleanupNewAuthUser(
          newlyCreatedUserId
        );
      }

      return res
        .status(
          500
        )
        .json({
          success:
            false,

          message:
            error?.message
            ||
            "Client registration failed."
        });
    }
  }
);

app.post(
  "/api/register/lawyer",

  lawyerPhotoUpload.single(
    "profilePhoto"
  ),

  async (
    req,
    res
  ) => {
    let newlyCreatedUserId =
      null;

    let uploadedPhotoPath =
      null;

    try {
      const fullName =
        normalizeText(
          req.body.fullName
        );

      const email =
        normalizeEmail(
          req.body.email
        );

      const password =
        String(
          req.body.password || ""
        );

      const phone =
        normalizeText(
          req.body.phone
        );

      const birthDate =
        normalizeText(
          req.body.birthDate
        );

      const degree =
        normalizeText(
          req.body.degree
          ||
          req.body.education
        );

      const collegeUniversity =
        normalizeText(
          req.body.collegeUniversity
          ||
          req.body.college
        );

      const graduationYear =
        safeNumber(
          req.body.graduationYear
        );

      const barCouncilNumber =
        normalizeText(
          req.body.barCouncilNumber
        );

      const barCouncilState =
        normalizeText(
          req.body.barCouncilState
        );

      const enrollmentNumber =
        normalizeText(
          req.body.enrollmentNumber
        );

      const yearsExperience =
        safeNumber(
          req.body.yearsExperience
        );

      const legalCategory =
        normalizeText(
          req.body.legalCategory
        )
          .toLowerCase();

      const consultationFee =
        safeNumber(
          req.body.consultationFee
        );

      const city =
        normalizeText(
          req.body.city
        );

      const state =
        normalizeText(
          req.body.state
        );

      const languages =
        parseLanguages(
          req.body.languages
        );

      if (
        !req.file
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Please upload a Lawyer profile photo."
          });
      }

      if (
        fullName.length <
        2
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter the Lawyer's full name."
          });
      }

      if (
        !validEmail(
          email
        )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid email address."
          });
      }

      if (
        password.length <
        8
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Password must contain at least 8 characters."
          });
      }

      if (
        !validIndianPhone(
          phone
        )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid 10-digit Indian mobile number."
          });
      }

      if (
        !birthDate
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Date of birth is required."
          });
      }

      if (
        !degree ||
        !collegeUniversity
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Education and college details are required."
          });
      }

      const currentYear =
        new Date()
          .getFullYear();

      if (
        !Number.isInteger(
          graduationYear
        )
        ||
        graduationYear <
        1950
        ||
        graduationYear >
        currentYear
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid graduation year."
          });
      }

      if (
        !barCouncilNumber ||
        !barCouncilState ||
        !enrollmentNumber
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Bar Council and enrollment details are required."
          });
      }

      if (
        !Number.isInteger(
          yearsExperience
        )
        ||
        yearsExperience <
        0
        ||
        yearsExperience >
        80
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter valid years of experience."
          });
      }

      if (
        ![
          "criminal",
          "family",
          "property",
          "corporate",
          "civil",
          "financial"
        ]
          .includes(
            legalCategory
          )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Select a valid NyayaSetu legal category."
          });
      }

      if (
        !Number.isFinite(
          consultationFee
        )
        ||
        consultationFee <
        0
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Enter a valid consultation fee."
          });
      }

      if (
        !city ||
        !state
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "City and State are required."
          });
      }

      if (
        languages.length ===
        0
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Select at least one language."
          });
      }

      const existingAuthUser =
        await findAuthUserByEmail(
          email
        );

      if (
        existingAuthUser
      ) {
        return res
          .status(
            409
          )
          .json({
            success:
              false,

            code:
              "ACCOUNT_ALREADY_EXISTS",

            message:
              "An account already exists with this email address. Please login instead."
          });
      }

      /*
         IMPORTANT:

         Your existing Supabase private.handle_new_user()
         trigger reads these exact metadata keys.

         That trigger creates:

         profiles
         lawyer_profiles
         lawyer_verification_details
         lawyer_approval_history
      */

      const {
        data:
          signupData,
        error:
          signupError
      } =
        await supabase
          .auth
          .signUp({
            email,
            password,

            options: {
              data: {
                role:
                  "lawyer",

                full_name:
                  fullName,

                display_name:
                  fullName,

                phone,
                city,
                state,

                birth_date:
                  birthDate,

                degree,

                college_university:
                  collegeUniversity,

                graduation_year:
                  String(
                    graduationYear
                  ),

                bar_council_number:
                  barCouncilNumber,

                bar_council_state:
                  barCouncilState,

                enrollment_number:
                  enrollmentNumber,

                legal_category:
                  legalCategory,

                years_experience:
                  String(
                    yearsExperience
                  ),

                consultation_fee:
                  String(
                    consultationFee
                  ),

                languages
              }
            }
          });

      if (
        signupError
      ) {
        throw signupError;
      }

      if (
        !signupData?.user?.id
      ) {
        throw new Error(
          "Lawyer Auth account could not be created."
        );
      }

      newlyCreatedUserId =
        signupData.user.id;

      const extension =
        getPhotoExtension(
          req.file.mimetype
        );

      uploadedPhotoPath =
        `${newlyCreatedUserId}/profile.${extension}`;

      const {
        error:
          photoError
      } =
        await supabaseAdmin
          .storage
          .from(
            "lawyer-profile-photos"
          )
          .upload(
            uploadedPhotoPath,
            req.file.buffer,
            {
              contentType:
                req.file.mimetype,

              upsert:
                true
            }
          );

      if (
        photoError
      ) {
        throw photoError;
      }

      /*
         Synchronize the profile created by the trigger.
      */

      const {
        error:
          profileError
      } =
        await supabaseAdmin
          .from(
            "profiles"
          )
          .upsert(
            {
              id:
                newlyCreatedUserId,

              role:
                "lawyer",

              full_name:
                fullName,

              phone:
                phone || null,

              city:
                city || null,

              state:
                state || null,

              is_active:
                true
            },

            {
              onConflict:
                "id"
            }
          );

      if (
        profileError
      ) {
        throw profileError;
      }

      /*
         Use ONLY real columns from lawyer_profiles.
      */

      const {
        error:
          lawyerProfileError
      } =
        await supabaseAdmin
          .from(
            "lawyer_profiles"
          )
          .upsert(
            {
              user_id:
                newlyCreatedUserId,

              display_name:
                fullName,

              legal_category:
                legalCategory,

              years_experience:
                yearsExperience,

              languages,

              consultation_fee:
                consultationFee,

              city,

              state,

              profile_photo_path:
                uploadedPhotoPath,

              approval_status:
                "PENDING",

              rejection_reason:
                null,

              approved_at:
                null,

              rejected_at:
                null,

              is_active:
                true
            },

            {
              onConflict:
                "user_id"
            }
          );

      if (
        lawyerProfileError
      ) {
        throw lawyerProfileError;
      }

      /*
         FINAL SCHEMA-CORRECT FIX

         Your actual table columns are:

         birth_date
         degree
         college_university
         graduation_year
         bar_council_number
         bar_council_state
         enrollment_number
      */

      const {
        error:
          verificationError
      } =
        await supabaseAdmin
          .from(
            "lawyer_verification_details"
          )
          .upsert(
            {
              lawyer_id:
                newlyCreatedUserId,

              birth_date:
                birthDate,

              degree,

              college_university:
                collegeUniversity,

              graduation_year:
                graduationYear,

              bar_council_number:
                barCouncilNumber,

              bar_council_state:
                barCouncilState,

              enrollment_number:
                enrollmentNumber
            },

            {
              onConflict:
                "lawyer_id"
            }
          );

      if (
        verificationError
      ) {
        throw verificationError;
      }

      newlyCreatedUserId =
        null;

      uploadedPhotoPath =
        null;

      return res
        .status(
          201
        )
        .json({
          success:
            true,

          message:
            "Lawyer registration submitted successfully. Your profile is pending Admin approval."
        });
    }
    catch (
      error
    ) {
      console.error(
        "Lawyer registration error:",
        error
      );

      if (
        uploadedPhotoPath
      ) {
        await cleanupLawyerPhoto(
          uploadedPhotoPath
        );
      }

      if (
        newlyCreatedUserId
      ) {
        await cleanupNewAuthUser(
          newlyCreatedUserId
        );
      }

      return res
        .status(
          500
        )
        .json({
          success:
            false,

          message:
            error?.message
            ||
            "Lawyer registration failed."
        });
    }
  }
);

app.post(
  "/api/auth/resend-confirmation",

  async (
    req,
    res
  ) => {
    try {
      const email =
        normalizeEmail(
          req.body?.email
        );

      if (
        !validEmail(
          email
        )
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "Please enter a valid email address."
          });
      }

      const existingUser =
        await findAuthUserByEmail(
          email
        );

      if (
        !existingUser
      ) {
        return res
          .status(
            404
          )
          .json({
            success:
              false,

            message:
              "No NyayaSetu account was found with this email address."
          });
      }

      if (
        existingUser.email_confirmed_at
      ) {
        return res
          .status(
            200
          )
          .json({
            success:
              true,

            message:
              "This email address is already confirmed. You can login to NyayaSetu."
          });
      }

      const {
        error
      } =
        await supabase
          .auth
          .resend({
            type:
              "signup",

            email
          });

      if (
        error
      ) {
        console.error(
          "Confirmation resend error:",
          error
        );

        return res
          .status(
            error.status || 400
          )
          .json({
            success:
              false,

            message:
              error.message
              ||
              "Unable to resend confirmation email."
          });
      }

      return res
        .status(
          200
        )
        .json({
          success:
            true,

          message:
            "Confirmation email sent again. Please check your Inbox, Spam and Promotions folders."
        });
    }
    catch (
      error
    ) {
      console.error(
        "Unexpected confirmation resend error:",
        error
      );

      return res
        .status(
          500
        )
        .json({
          success:
            false,

          message:
            error?.message
            ||
            "Unable to resend confirmation email."
        });
    }
  }
);

app.use(
  (
    error,
    req,
    res,
    next
  ) => {
    if (
      error instanceof
      multer.MulterError
    ) {
      if (
        error.code ===
        "LIMIT_FILE_SIZE"
      ) {
        return res
          .status(
            400
          )
          .json({
            success:
              false,

            message:
              "The Lawyer profile photo must be 5 MB or smaller."
          });
      }

      return res
        .status(
          400
        )
        .json({
          success:
            false,

          message:
            "Unable to process the uploaded Lawyer profile photo."
        });
    }

    if (
      error
    ) {
      console.error(
        "NyayaSetu request error:",
        error
      );

      return res
        .status(
          400
        )
        .json({
          success:
            false,

          message:
            error.message
            ||
            "The request could not be processed."
        });
    }

    next();
  }
);

app.use(
  (
    req,
    res
  ) => {
    return res
      .status(
        404
      )
      .json({
        success:
          false,

        message:
          "NyayaSetu backend route not found."
      });
  }
);

if (!process.env.NETLIFY && !process.env.NETLIFY_DEV) {
  app.listen(
    PORT,

    () => {
      console.log(
        "============================================"
      );

      console.log(
        "NYAYASETU BACKEND STARTED"
      );

      console.log(
        `http://localhost:${PORT}`
      );

      console.log(
        `Health check: http://localhost:${PORT}/api/health`
      );

      console.log(
        "Client registration: POST /api/register/client"
      );

      console.log(
        "Lawyer registration + photo: POST /api/register/lawyer"
      );

      console.log(
        "Receipt PDF generation: POST /api/admin/payments/:paymentId/generate-receipt-pdf"
      );

      console.log(
        "============================================"
      );
    }
  );
}

export default app; 