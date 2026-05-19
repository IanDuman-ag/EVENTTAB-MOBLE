# Directive: Email Setup

## Goal
Configure Django to send password reset emails via SMTP.

## Default behavior (no config needed)
By default, Django uses `console.EmailBackend` which prints emails to the terminal instead of sending them. This is perfect for local development — you'll see the reset code in the Django server logs.

## Production setup (Gmail example)

### 1. Get a Gmail App Password
1. Go to your Google Account → Security
2. Enable 2-Step Verification if not already enabled
3. Go to "App passwords" (search for it in settings)
4. Generate a new app password for "Mail"
5. Copy the 16-character password

### 2. Update `.env`
```bash
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-16-char-app-password
DEFAULT_FROM_EMAIL=Eventtab <your-email@gmail.com>
```

### 3. Restart Django
```bash
.\venv\Scripts\python.exe backend\manage.py runserver
```

## Other SMTP providers

### SendGrid
```bash
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=your-sendgrid-api-key
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### Mailgun
```bash
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=postmaster@your-mailgun-domain.com
EMAIL_HOST_PASSWORD=your-mailgun-smtp-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### AWS SES
```bash
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=email-smtp.us-east-1.amazonaws.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-ses-smtp-username
EMAIL_HOST_PASSWORD=your-ses-smtp-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

## Testing

### Console backend (default)
When `EMAIL_BACKEND` is not set or set to `console.EmailBackend`, emails print to the Django terminal:

```
Content-Type: text/plain; charset="utf-8"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Subject: Eventtab - Password Reset Code
From: noreply@eventtab.dev
To: user@example.com

Hello testuser,

You requested a password reset for your Eventtab account.

Your reset code is:

vRA4OIxRynI9y8NNq3Ec9V4wmSVN6rQd0KZI

This code will expire in 30 minutes.
...
```

Just copy the token from the terminal and paste it into the Flutter app.

### Real SMTP
1. Configure `.env` with real SMTP credentials
2. Restart Django
3. Request a password reset in the Flutter app
4. Check the email inbox for the reset code

## Troubleshooting

**"SMTPAuthenticationError: Username and Password not accepted"**
- Gmail: Make sure you're using an App Password, not your regular password
- Check that 2-Step Verification is enabled

**"SMTPServerDisconnected: Connection unexpectedly closed"**
- Check `EMAIL_PORT` (587 for TLS, 465 for SSL)
- Verify `EMAIL_USE_TLS=True` for port 587

**Email not arriving**
- Check spam folder
- Verify `EMAIL_HOST_USER` is correct
- Check Django logs for errors

## Scripts
- `execution/test_email.py` — sends a test email to verify SMTP config

## Learnings
_(update this section as you discover email delivery issues)_
