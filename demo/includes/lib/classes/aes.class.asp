<%
		
	'*******************************************'
	' AES-256-CBC with HMAC-SHA-256 in VBScript '
	' Original code:                            '
	' https://github.com/susam/aes.vbs          '
	'*******************************************'

	Class AdvancedEncryptionStandard
	
		Dim utf8, b64Enc, b64Dec, mac, aes, mem, hAlg, hEnc, i,_ 
		diff, offset, length, tokens, blockSize, b64Block, bytes,_
		ivBytes, cipherBytes, plainBytes, macBytes, aesKeyBytes,_ 
		macKeyBytes, macActual, result, aesEnc, aesDec, enc, dec,_ 
		key, macKey
		
		Public sha256Token
		
		Private Sub Class_Initialize()
		
			Set utf8 = Server.CreateObject("System.Text.UTF8Encoding")
			Set b64Enc = Server.CreateObject("System.Security.Cryptography.ToBase64Transform")
			Set b64Dec = Server.CreateObject("System.Security.Cryptography.FromBase64Transform")
			Set mac = Server.CreateObject("System.Security.Cryptography.HMACSHA256")
			Set aes = Server.CreateObject("System.Security.Cryptography.RijndaelManaged")
			Set mem = Server.CreateObject("System.IO.MemoryStream")
			Set hAlg = Server.CreateObject("System.Security.Cryptography.SHA256Managed")
			Set hEnc = Server.CreateObject("MSXML2.DomDocument").CreateElement("encode")
			
			' Format the key constants
			
			key = B64Encode(utf8.GetBytes_4(AesEncryptionKey))
			macKey = B64Encode(utf8.GetBytes_4(AesMacKey))
									
		End Sub
		
		Private Sub Class_Terminate()
						
			Set utf8 = Nothing
			Set b64Enc = Nothing
			Set b64Dec = Nothing
			Set mac = Nothing
			Set aes = Nothing
			Set mem = Nothing
			Set hAlg = Nothing
			Set hEnc = Nothing
			
		End Sub
		
		'******************************************************'
		' Return the minimum value between two integer values. '
		'******************************************************'
		' Arguments:                                           '
		'   a (Long): An integer.                              '
		'   b (Long): Another integer.                         '
		'                                                      '
		' Return:                                              '
		'   Long: Minimum of the two integer values.           '
		'******************************************************'
		
		Private Function Min(a,b)
		
			Min = a
			If b < a Then Min = b
			
		End Function
		
		'***************************************************************'
		' Convert a byte array to a Base64 string representation of it. '
		'***************************************************************'
		' Arguments:                                                    '
		'   bytes (Byte()): Byte array.                                 '
		'                                                               '
		' Returns:                                                      '
		'   String: Base64 representation of the input byte array.      '
		'***************************************************************'
		
		Private Function B64Encode(bytes)
						
			blockSize = b64Enc.InputBlockSize
			
			result = ""
			
			For offset = 0 To LenB(bytes)-1 Step blockSize
			
				length = Min(blockSize,LenB(bytes)-offset)
				
				b64Block = b64Enc.TransformFinalBlock((bytes),offset,length)
				
				result = result & utf8.GetString((b64Block))
				
			Next
			
			B64Encode = result
			
		End Function
		
		'***********************************************************'
		' Convert a Base64 string to a byte array.                  '
		'***********************************************************'
		' Arguments:                                                '
		'   b64Str (String): Base64 string.                         '
		'                                                           '
		' Returns:                                                  '
		'   Byte(): A byte array that the Base64 string decodes to. '
		'***********************************************************'
		
		Function B64Decode(b64Str)
							
			bytes = utf8.GetBytes_4(b64Str)
			
			B64Decode = b64Dec.TransformFinalBlock((bytes),0,LenB(bytes))
			
		End Function
		
		'**********************************************'
		' Escape Base64 string for safe cookie storage '
		'**********************************************'

		Private Function EscapeB64(b64Str)
		
			b64Str = Replace(b64Str,"+","-")
			b64Str = Replace(b64Str,"=","_")
			b64Str = Replace(b64Str,"/","~")
			
			EscapeB64 = b64Str
			
		End Function
		
		'******************************************'
		' Unescape Base64 string for safe decoding '
		'******************************************'

		Private Function UnescapeB64(b64Str)
			
			b64Str = Replace(b64Str,"-","+")
			b64Str = Replace(b64Str,"_","=")
			b64Str = Replace(b64Str,"~","/")
			
			UnescapeB64 = b64Str
			
		End Function
		
		'*************************************'
		' Concatenate two byte arrays.        '
		'*************************************'
		' Arguments:                          '
		'   a (Byte()): A byte array.         '
		'   b (Byte()): Another byte array.   '
		'                                     '
		' Returns:                            '
		'   Byte(): Concatenated byte arrays. '
		'*************************************'
		
		Private Function ConcatBytes(a,b)
		
			mem.SetLength(0)
			
			mem.Write (a),0,LenB(a)
			mem.Write (b),0,LenB(b)
			
			ConcatBytes = mem.ToArray()
			
		End Function
		
		'*****************************************************************'
		' Check if two byte arrays are equal.                             '
		'*****************************************************************'
		' Arguments:                                                      '
		'   a (Byte()): A byte array.                                     '
		'   b (Byte()): Another byte array.                               '
		'                                                                 '
		' Returns:                                                        '
		'   Boolean: True if both byte arrays are equal; False otherwise. '
		'*****************************************************************'

		Private Function EqualBytes(a,b)
						
			EqualBytes = False
			
			If LenB(a) <> LenB(b) Then Exit Function
			
			diff = 0
			
			For i = 1 to LenB(a)
				diff = diff Or (AscB(MidB(a,i,1)) Xor AscB(MidB(b,i,1)))
			Next
			
			EqualBytes = Not diff
			
		End Function
		
		'*********************************************************'
		' Compute message authentication code using HMAC-SHA-256. '
		'*********************************************************'
		' Arguments:                                              '
		'   msgBytes (Byte()): Message to be authenticated.       '
		'   keyBytes (Byte()): Secret key.                        '
		'                                                         '
		' Returns:                                                '
		'   Byte(): Message authenticate code.                    '
		'*********************************************************'

		Private Function ComputeMAC(msgBytes,keyBytes)
		
			mac.Key = keyBytes
			
			ComputeMAC = mac.ComputeHash_2((msgBytes))
			
		End Function
		
		'************************************************************************'
		' Encrypt plaintext and compute MAC for the result.                      '
		'************************************************************************'
		' The length of AES encryption key (aesKey) must be 256 bits (32 bytes). '
		' It must be provided as a Base64 encoded string. On macOS or Linux,     '
		' enter this command to generate a Base64 encoded 256-bit key:           '
		'                                                                        '
		'   head -c32 /dev/urandom | base64                                      '
		'                                                                        '
		' The HMAC secret key (macKey) can be any length but a minimum of        '
		' 256 bits (32 bytes) is recommended as the length of this key. It must  '
		' be provided as a Base64 encoded string.                                '
		'                                                                        '
		' The return value of this function is composed of the following three   '
		' Base64 encoded strings joined with colons:                             '
		'                                                                        '
		'   - Message authentication code.                                       '
		'   - Randomly generated 128-bit initialization vector (IV).             '
		'   - Ciphertext.                                                        '
		'                                                                        '
		' Note:                                                                  '
		'                                                                        '
		'   - A 256-bit key after Base64 encoding contains 44 characters         '
		'     including one '=' character as padding at the end.                 '
		'   - A 128-bit IV after Base64 encoding contains 24 characters          '
		'     including two '=' characters as padding at the end.                '
		'                                                                        '
		' Arguments:                                                             '
		'   plaintext (String): Text to be encrypted.                            '
		'   aesKey (String): AES encryption key encoded as a Base64 string.      '
		'   macKey (String): HMAC secret key encoded as a Base64 string.         '
		'                                                                        '
		' Returns:                                                               '
		'   String: MAC, IV, and ciphertext joined with colons.                  '
		'************************************************************************'

		Public Function Encrypt(plaintext)
				
			aes.GenerateIV()
			
			aesKeyBytes = B64Decode(key)
			macKeyBytes = B64Decode(macKey)
			
			Set aesEnc = aes.CreateEncryptor_2((aesKeyBytes),aes.IV)
			
				plainBytes = utf8.GetBytes_4(plaintext)
				
				cipherBytes = aesEnc.TransformFinalBlock((plainBytes),0,LenB(plainBytes))
				
				macBytes = ComputeMAC(ConcatBytes(aes.IV,cipherBytes),macKeyBytes)
				
				Encrypt = B64Encode(macBytes) & ":" &_
						  B64Encode(aes.IV) & ":" &_
						  B64Encode(cipherBytes)
						  
				Encrypt = EscapeB64(Encrypt)
					  
			Set aesEnc = Nothing
			
			' Generate the sha256 authentication token
			
			sha256Token = Hash(Encrypt & AesSha256Secret,"Sha256")
									
		End Function
		
		'**********************************************************************'
		' Decrypt ciphertext after authenticating IV and ciphertext using MAC. '
		'**********************************************************************'
		' MAC, IV, and ciphertext must be encoded in Base64. They are provided '
		' together as a single string with the Base64 encoded values separated '
		' by colons. See the comment for Encrypt() function to read more about '
		' the format.                                                          '
		'                                                                      '
		' Arguments:                                                           '
		'   macIVCipherText (String): Colon separated MAC, IV, and ciphertext. '
		'   aesKey (String): AES encryption key encoded as a Base64 string.    '
		'   macKey (String): HMAC secret key encoded as a Base64 string.       '
		'                                                                      '
		' Returns:                                                             '
		'   String: Plaintext that the given ciphertext decrypts to.           '
		'**********************************************************************'
		
		Public Function Decrypt(macIVCiphertext)
						
			macIVCiphertext = UnescapeB64(macIVCiphertext)			
						
			aesKeyBytes = B64Decode(key)
			macKeyBytes = B64Decode(macKey)
			
			tokens = Split(macIVCiphertext,":")
						
			macBytes = B64Decode(tokens(0))
			ivBytes = B64Decode(tokens(1))
			cipherBytes = B64Decode(tokens(2))
			
			macActual = ComputeMAC(ConcatBytes(ivBytes,cipherBytes),macKeyBytes)
			
			If Not EqualBytes(macBytes,macActual) Then
				Err.Raise vbObjectError + 1000, "Decrypt()", "Bad MAC"
			End If
			
			Set aesDec = aes.CreateDecryptor_2((aesKeyBytes),(ivBytes))
			
				plainBytes = aesDec.TransformFinalBlock((cipherBytes),0,LenB(cipherBytes))
				
				Decrypt = utf8.GetString((plainBytes))
			
			Set aesDec = Nothing
			
		End Function
		
		'***************************************************************'
		' Show interesting properties of cryptography objects used here '
		'***************************************************************'
		
		Public Function CryptoInfo()
		
			Set enc = aes.CreateEncryptor_2(aes.Key, aes.IV)
			Set dec = aes.CreateDecryptor_2(aes.Key, aes.IV)

				CryptoInfo = "aes.BlockSize: " & aes.BlockSize & VBlf & _
				"aes.FeedbackSize: " & aes.FeedbackSize & VBlf & _
				"aes.KeySize: " & aes.KeySize & VBlf & _
				"aes.Mode: " & aes.Mode & VBlf & _
				"aes.Padding: " & aes.Padding & VBlf & _
				"mac.HashName: " & mac.HashName & VBlf & _
				"mac.HashSize: " & mac.HashSize & VBlf & _
				"aesEnc.InputBlockSize: " & enc.InputBlockSize & VBlf & _
				"aesEnc.OutputBlockSize: " & enc.OutputBlockSize & VBlf & _
				"aesDec.InputBlockSize: " & enc.InputBlockSize & VBlf & _
				"aesDec.OutputBlockSize: " & enc.OutputBlockSize & VBlf & _
				"b64Enc.InputBlockSize: " & b64Enc.InputBlockSize & VBlf & _
				"b64Enc.OutputBlockSize: " & b64Enc.OutputBlockSize & VBlf & _
				"b64Dec.InputBlockSize: " & b64Dec.InputBlockSize & VBlf & _
				"b64Dec.OutputBlockSize: " & b64Dec.OutputBlockSize
				
			Set dec = Nothing
			Set enc = Nothing
			
		End Function
	
	End Class

%>