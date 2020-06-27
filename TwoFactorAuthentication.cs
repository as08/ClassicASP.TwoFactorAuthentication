using System;
using System.Text;
using OtpNet;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

namespace TwoFactorAuthentication
{

    [ProgId("ClassicASP.TwoFactorAuthentication")]

    [ClassInterface(ClassInterfaceType.AutoDual)]

    [Guid("70D8EC55-1164-4E70-A356-2245BE90C25E")]

    [ComVisible(true)]

    public class TwoFactorAuthentication
    {
        
        [ComVisible(true)]

        private long timeWindowUsed;
        public int _SecretKeyLength = 20;
        public string _HashMode = "sha1";
        public int _totpSize = 6;

        private const string rndChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        RNGCryptoServiceProvider CryptoRNG = new RNGCryptoServiceProvider();

        public void SecretKeyLength(int KeyLength){_SecretKeyLength = KeyLength;}

        public void HashMode(string HashAlg){_HashMode = HashAlg;}

        public void totpSize(int digits){_totpSize = digits;}

        public string GenerateSecretKey()
        {
            var key = KeyGeneration.GenerateRandomKey(_SecretKeyLength);
            var base32String = Base32Encoding.ToString(key);
            return base32String.Replace("=","");
        }

        public bool Verify(string SecretKey, string totpCode)
        {
            var theHMAC = OtpHashMode.Sha1; // Default

            if (_HashMode.Contains("sha2")){theHMAC = OtpHashMode.Sha256;}
            else if (_HashMode.Contains("sha5")){theHMAC = OtpHashMode.Sha512;}

            var base32Bytes = Base32Encoding.ToBytes(SecretKey);
            var totp = new Totp(base32Bytes, mode: theHMAC, totpSize: _totpSize);
            var window = new VerificationWindow(previous: 1, future: 1);
            return totp.VerifyTotp(totpCode, out timeWindowUsed, VerificationWindow.RfcSpecifiedNetworkDelay);
        }

        public string RecoveryPassword(int strLen)
        {
            StringBuilder res = new StringBuilder();
            using (CryptoRNG)
            {
                byte[] uintBuffer = new byte[sizeof(uint)];

                while (strLen-- > 0)
                {
                    CryptoRNG.GetBytes(uintBuffer);
                    uint num = BitConverter.ToUInt32(uintBuffer, 0);
                    res.Append(rndChars[(int)(num % (uint)rndChars.Length)]);
                }
            }
            return res.ToString();
        }

    }
}
