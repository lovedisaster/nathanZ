using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace FolderFilterApp
{
    /// <summary>
    /// This object eliminates directories with no sub folders from a input string. 
    /// </summary>
    public class FolderFilter
    {
        /// <summary>
        /// Creates an instance of FolderFilter.
        /// </summary>
        public FolderFilter()
        {
        }

        /// <summary>
        /// Split a string into an string array.  
        /// </summary>
        /// <param name="folderString">The folder string which contains multiple directory names and seperators.</param>
        /// <returns>A array response containing a list of directory paths.</returns>
        private string[] GenerateFolderList(string folderString)
        {
            string[] folderList = folderString.Split(' ');
            return folderList;
        }

        /// <summary>
        /// Remove folder list memebers which contains no sub-directory. Assemble the new output string. 
        /// </summary>
        /// <param name="inputMessage">A string which contains multiple directory names and seperators. This is keyed in by user.</param>
        /// <returns>A output string without one-level directory path.</returns>
        public string FilterFolders(string inputMessage)
        {
            string[] folderList = GenerateFolderList(inputMessage);
            string outputMessage = "";
            for (int i = 0; i < folderList.Length; i++)
            {
                if (folderList[i].Contains('/'))
                {
                    outputMessage += folderList[i] += ' ';
                }
            }
            return outputMessage;
        }

    }
}
