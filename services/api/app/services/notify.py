"""Ticket emails over SMTP. With SMTP_HOST unset, nothing is sent and the buyer
relies on the order link shown after checkout."""

import logging
import smtplib
from datetime import timedelta, timezone
from email.message import EmailMessage

from app.core.config import get_settings
from app.core.time import aware
from app.models import Event, Order

log = logging.getLogger(__name__)

# Trinidad & Tobago is UTC-4 all year (no daylight saving).
TT = timezone(timedelta(hours=-4), "AST")


def order_link(order: Order) -> str:
    base = get_settings().public_base_url.rstrip("/")
    return f"{base}/orders/{order.id}?token={order.access_token}"


def ticket_email(order: Order, event: Event) -> EmailMessage | None:
    settings = get_settings()
    if not settings.smtp_host or not order.buyer_email:
        return None
    count = sum(i.quantity for i in order.items)
    msg = EmailMessage()
    msg["Subject"] = f"Your tickets: {event.title}"
    msg["From"] = settings.smtp_from
    msg["To"] = order.buyer_email
    when = aware(event.starts_at).astimezone(TT).strftime("%a %d %b %Y, %I:%M %p")
    where = f"\n{event.venue_name}" if event.venue_name else ""
    msg.set_content(
        f"Hi {order.buyer_name or 'there'},\n\n"
        f"You're going to {event.title}!\n{when}{where}\n\n"
        f"Your {count} ticket{'s' if count != 1 else ''}, with the QR codes to show at the gate:\n"
        f"{order_link(order)}\n\n"
        "Keep this link private: anyone with it can use your tickets.\n\n"
        "Lehwi Palance\n"
    )
    return msg


def send(msg: EmailMessage) -> None:
    settings = get_settings()
    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            if settings.smtp_starttls:
                smtp.starttls()
            if settings.smtp_username:
                smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(msg)
    except Exception:  # an email failure must never undo a sale
        log.exception("could not send ticket email to %s", msg["To"])
