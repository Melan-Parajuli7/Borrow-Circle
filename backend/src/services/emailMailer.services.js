// require("dotenv").config();
// const nodemailer = require("nodemailer");

// const transporter = nodemailer.createTransport({
//   service: "gmail",
//   auth: {
//     type: "OAuth2",
//     user: process.env.EMAIL_USER,
//     clientId: process.env.CLIENT_ID,
//     clientSecret: process.env.CLIENT_SECRET,
//     refreshToken: process.env.REFRESH_TOKEN,
//   },
// });

// // Verify the connection configuration
// transporter.verify((error) => {
//   if (error) {
//     console.error("Error connecting to email server:", error);
//   } else {
//     console.log("Email server is ready to send messages");
//   }
// });

// // Escape user-supplied strings before embedding them in HTML
// function escapeHtml(str = "") {
//   return String(str)
//     .replace(/&/g, "&amp;")
//     .replace(/</g, "&lt;")
//     .replace(/>/g, "&gt;")
//     .replace(/"/g, "&quot;")
//     .replace(/'/g, "&#39;");
// }

// async function sendRegistrationEmail(userEmail, name) {
//   const safeName = escapeHtml(name);

//   const subject = "Welcome to BorrowCircle!";

//   const text = `Hello ${name},

// Thank you for registering with BorrowCircle.
// We are excited to have you on board!

// BorrowCircle helps university students lend and borrow academic items such as calculators, textbooks, lab equipment, and project tools in a safe and organized way.

// Best Regards,
// BorrowCircle Team`;

//   const html = `
// <!DOCTYPE html>
// <html lang="en">
// <head>
//   <meta charset="UTF-8" />
//   <meta name="viewport" content="width=device-width, initial-scale=1.0" />
//   <title>Welcome to BorrowCircle</title>
// </head>
// <body style="margin:0; padding:0; background-color:#f0fdfa; font-family:Arial, Helvetica, sans-serif;">
//   <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#f0fdfa; padding:24px 0;">
//     <tr>
//       <td align="center">
//         <table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="max-width:600px; width:100%; background-color:#ffffff; border-radius:8px; overflow:hidden;">

//           <!-- Header -->
//           <tr>
//             <td align="center" style="background-color:#0F766E; padding:32px 24px;">
//               <h1 style="margin:0; color:#ffffff; font-size:28px; letter-spacing:0.5px;">BorrowCircle</h1>
//               <p style="margin:8px 0 0; color:#ccfbf1; font-size:14px;">Campus Item Lending Made Simple</p>
//             </td>
//           </tr>

//           <!-- Body -->
//           <tr>
//             <td style="padding:32px 32px 16px; color:#1f2937; font-size:16px; line-height:1.6;">
//               <h2 style="margin:0 0 16px; font-size:22px; color:#111827;">Hello ${safeName},</h2>
//               <p style="margin:0 0 16px;">
//                 Thank you for registering with <strong>BorrowCircle</strong>. We are excited to have you on board!
//               </p>
//               <p style="margin:0 0 16px;">
//                 BorrowCircle is a campus lending platform that helps university students share academic items easily and responsibly. With your new account, you can:
//               </p>
//               <ul style="margin:0 0 16px; padding-left:20px;">
//                 <li style="margin-bottom:8px;">List items you want to lend (calculators, books, lab equipment, etc.)</li>
//                 <li style="margin-bottom:8px;">Search and request items from other students or campus groups</li>
//                 <li style="margin-bottom:8px;">Confirm handovers securely using QR code or one-time code</li>
//                 <li style="margin-bottom:8px;">Track active loans and leave reviews after returning items</li>
//               </ul>
//               <p style="margin:0 0 16px;">
//                 Start sharing and borrowing within your university community today!
//               </p>
//             </td>
//           </tr>

//           <!-- Footer -->
//           <tr>
//             <td style="background-color:#f0fdfa; padding:24px 32px; border-top:1px solid #ccfbf1; color:#64748b; font-size:13px; line-height:1.5;" align="center">
//               <p style="margin:0 0 8px;">Best Regards,<br /><strong>BorrowCircle Team</strong></p>
//               <p style="margin:0;">&copy; ${new Date().getFullYear()} BorrowCircle. All rights reserved.</p>
//             </td>
//           </tr>

//         </table>
//       </td>
//     </tr>
//   </table>
// </body>
// </html>`;

//   const info = await transporter.sendMail({
//     from: `"BorrowCircle" <${process.env.EMAIL_USER}>`,
//     to: userEmail,
//     subject,
//     text,
//     html,
//   });

//   console.log("Message sent: %s", info.messageId);
//   return info;
// }

// module.exports = { sendRegistrationEmail };