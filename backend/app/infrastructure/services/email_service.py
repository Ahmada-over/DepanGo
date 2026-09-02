import os
import resend
from dotenv import load_dotenv

load_dotenv()

resend.api_key = os.environ.get("RESEND_API_KEY")

class EmailService:
    @staticmethod
    def send_otp_email(user_email: str, otp_code: str):
        if not resend.api_key:
            print("ERREUR: RESEND_API_KEY n'est pas défini dans le fichier .env")
            return False
            
        params = {
            "from": "DepanGo <onboarding@resend.dev>",
            "to": [user_email],
            "subject": "Votre code de sécurité DepanGo",
            "html": f"<p>Bonjour,</p><p>Votre code de sécurité est le : <strong>{otp_code}</strong>.</p><p>Ce code expire dans 10 minutes.</p>",
        }
        
        try:
            response = resend.Emails.send(params)
            print(f"Email OTP envoyé avec succès à {user_email}")
            return True
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email OTP: {e}")
            return False
