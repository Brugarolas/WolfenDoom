/*
 * Copyright (c) 2021 Talon1024
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
**/

class MessageLogHandler : EventHandler
{
	Array<String> messages;
	Dictionary images; // In case a message should have an image appear beside it

	override void OnRegister()
	{
		if (!images)
		{
			images = Dictionary.Create();
		}
	}

	static void Add(String message, String image = "")
	{
		MessageLogHandler handler = MessageLogHandler(EventHandler.Find("MessageLogHandler"));
		if (!handler) { return; }
		handler.messages.Push(message);
		if (image.Length())
		{
			handler.images.Insert(message, image);
		}
	}
}

class MessageLogMenu : GenericMenu
{
	Array<String> lines; // Text line strings
	Array<int> xoffsets; // X offsets of text lines
	Dictionary images; // Line number (Array index) to image
	int msgWidth; // Width available for drawing text
	int maxLines; // Maximum number of lines which can be drawn
	int minLine; // Minimum or "current" line
	// Scroll bar graphics
	TextureID scrollTop;
	TextureID scrollMid;
	TextureID scrollBot;
	TextureID arrowUp;
	TextureID arrowDown;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		images = Dictionary.Create();
		// Display messages in a 4:3 "space", with side padding.
		// 20 px = 10px padding on both sides
		// 32 px = width of the scroll bar graphics
		msgWidth = min(Screen.GetWidth(), Screen.GetWidth() * (4./3) / Screen.GetAspectRatio()) - 52;
		// How many lines, at most, should be displayed?
		maxLines = int(ceil(Screen.GetHeight() * .875 / (smallfont.GetHeight() * CleanYFac_1)));
		scrollTop = TexMan.CheckForTexture("graphics/conversation/Scroll_T.png");
		scrollMid = TexMan.CheckForTexture("graphics/conversation/Scroll_M.png");
		scrollBot = TexMan.CheckForTexture("graphics/conversation/Scroll_B.png");
		arrowUp = TexMan.CheckForTexture("graphics/conversation/Arrow_Up.png");
		arrowDown = TexMan.CheckForTexture("graphics/conversation/Arrow_Dn.png");
		MessageLogHandler log = MessageLogHandler(EventHandler.Find("MessageLogHandler"));
		if (!log) { return; }
		// Add all of the messages from the log handler to the "menu"
		for(int i = 0; i < log.messages.Size(); i++)
		{
			String image = log.images.At(log.messages[i]);
			addMessage(log.messages[i], image);
		}
		minLine = max(0, lines.Size() - maxLines);
	}

	// Push to both arrays so that they are the same size
	protected ui void addLine(String text, int offset = 0)
	{
		lines.Push(text);
		xoffsets.Push(offset);
	}

	protected ui void addMessage(String message, String image = "")
	{
		// Prepare image
		int imageWidth = 0;
		int imageLines = 0;
		if (image.Length())
		{
			TextureID imageTexture = TexMan.CheckForTexture(image);
			if (imageTexture)
			{
				int imageHeight;
				[imageWidth, imageHeight] = TexMan.GetSize(imageTexture);
				imageLines = int(ceil(double(imageHeight) / smallfont.GetHeight()));
			}
		}
		String fulltext = "";
		if (message.ByteAt(0) == 124) // '|'
		{
			fulltext = StringTable.Localize(message.Mid(1), false);
		}
		else
		{
			Array<String> pieces;
			message.Split(pieces, "|", TOK_SKIPEMPTY);
			for (int i = 0; i < pieces.Size(); i++)
			{
				fulltext = fulltext .. StringTable.Localize(pieces[i], false);
			}
		}
		// Break text into lines
		BrokenString breakInfo;
		String textLines;
		[textLines, breakInfo] = BrokenString.BreakString(fulltext, (msgWidth - (imageWidth ? 6 : 0) - imageWidth * CleanXFac_1) / CleanXFac_1, fnt: smallfont);
		// Add lines
		int firstLineNumber = lines.Size();
		if (firstLineNumber)
		{
			addLine(""); // Private use character - separator graphic in smallfont
			firstLineNumber += 1; // So that images are drawn - the drawer
			// checks the text line, not the separator line.
		}
		for (int i = 0; i <= breakInfo.Count(); i++)
		{
			addLine(breakInfo.StringAt(i), imageWidth ? imageWidth + 6 : 0);
		}
		if ((breakInfo.Count() + 1) < imageLines)
		{
			for (int i = (breakInfo.Count() + 1); i <= imageLines; i++)
			{
				addLine(""); // Blank lines don't need to have offsets
			}
		}
		if (imageWidth)
		{
			String lineNumString = String.Format("%d", firstLineNumber);
			images.Insert(lineNumString, image);
		}
	}

	override void Drawer()
	{
		if (lines.Size())
		{
			// Left-hand edge of the 4:3 box, plus 10px for left-hand padding
			double xpos = max(0, Screen.GetWidth() / 2 * (1 - (4./3) / Screen.GetAspectRatio())) + 10 * CleanXFac_1;
			int maxLine = min(lines.Size(), minLine + maxLines);
			double ystart = Screen.GetHeight() * .0625;
			double ypos = ystart;
			// Draw the messages
			for (int line = minLine; line < maxLine; line++)
			{
				double textXpos = xpos + xoffsets[line] * CleanXFac_1;
				if (lines[line] == "")
				{ // Draw a separator
					Screen.DrawText(smallfont, Font.CR_GRAY, textXpos, ypos, "", DTA_CleanNoMove_1, true);
					textXpos += smallfont.GetCharWidth(0xE000) * CleanXFac_1;
					int endSepWidth = smallfont.GetCharWidth(0xE002) * CleanXFac_1;
					while (textXpos < (msgWidth + xpos - endSepWidth))
					{
						Screen.DrawText(smallfont, Font.CR_GRAY, textXpos, ypos, "", DTA_CleanNoMove_1, true);
						textXpos += smallfont.GetCharWidth(0xE001) * CleanXFac_1;
					}
					Screen.DrawText(smallfont, Font.CR_GRAY, textXpos, ypos, "", DTA_CleanNoMove_1, true);
				}
				else
				{
					// Draw text
					Screen.DrawText(smallfont, Font.CR_GRAY, textXpos, ypos, lines[line], DTA_CleanNoMove_1, true);
					// Draw image
					String lineNumString = String.Format("%d", line);
					String imageName = images.At(lineNumString);
					if (imageName.Length())
					{
						TextureID imageTexture = TexMan.CheckForTexture(imageName);
						Screen.DrawTexture(imageTexture, true, xpos, ypos, DTA_CleanNoMove_1, true);
						// Draw border around image (debug)
						/*
						int imageWidth, imageHeight;
						[imageWidth, imageHeight] = TexMan.GetSize(imageTexture);
						Screen.DrawLineFrame(Color(255, 255, 0, 0), int(xpos), int(ypos), imageWidth * CleanXFac_1, imageHeight * CleanYFac_1);
						*/
					}
				}
				ypos += smallfont.GetHeight() * CleanYFac_1;
			}
			// Draw the scroll bar
			if (lines.Size() > maxLines)
			{
				// xpos is at the left side of the lines, so move it to the
				// right side to draw the scroll bar graphics.
				xpos += msgWidth;
				ypos = ystart;
				Screen.DrawTexture(arrowUp, false, xpos, ypos);
				// The total height of the scroll bar is the screen height *
				// .875. The height of each scrollbar graphic is 32. Two arrows
				// at the top and bottom make 64.
				double scrollBarHeight = Screen.GetHeight() * .875 - 64;
				double scrollBarPct = double(minLine) / lines.Size();
				ypos = ystart + 32 + scrollBarHeight * scrollBarPct;
				Screen.DrawTexture(scrollTop, false, xpos, ypos);
				ypos += 32;
				Screen.DrawTexture(scrollMid, false, xpos, ypos);
				ypos += 32;
				Screen.DrawTexture(scrollBot, false, xpos, ypos);
				// Max height for drawing text, plus height of first line
				ypos = Screen.GetHeight() * .9375;
				Screen.DrawTexture(arrowDown, false, xpos, ypos);
			}
		}
		else
		{
			String emptyLogText = StringTable.Localize("MESSAGELOGEMPTY", false);
			double xpos = (CleanWidth_1 * CleanXFac_1 / 2) - (smallfont.StringWidth(emptyLogText) * CleanXFac_1 / 2);
			double ypos = (CleanHeight_1 * CleanYFac_1 / 2) - (smallfont.GetHeight() * CleanYFac_1 / 2);
			Screen.DrawText(smallfont, Font.CR_GRAY, xpos, ypos, emptyLogText, DTA_CleanNoMove_1, true);
		}
	}
}

// openmenu MessageLogMenu
