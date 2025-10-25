import axios from 'axios';
import { PINATA_JWT } from '../config';

const PINATA_API_URL = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
const PINATA_JSON_URL = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';

// Upload a file to IPFS via Pinata
export const uploadFileToIPFS = async (file) => {
  try {
    const formData = new FormData();
    formData.append('file', file);

    const response = await axios.post(PINATA_API_URL, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
        'Authorization': `Bearer ${PINATA_JWT}`
      }
    });

    return `ipfs://${response.data.IpfsHash}`;
  } catch (error) {
    console.error('Error uploading file to IPFS:', error);
    throw error;
  }
};

// Upload JSON metadata to IPFS
export const uploadJSONToIPFS = async (json) => {
  try {
    const response = await axios.post(PINATA_JSON_URL, json, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PINATA_JWT}`
      }
    });

    return `ipfs://${response.data.IpfsHash}`;
  } catch (error) {
    console.error('Error uploading JSON to IPFS:', error);
    throw error;
  }
};

// Fetch from IPFS (converts ipfs:// to https gateway)
export const fetchFromIPFS = async (ipfsUri) => {
  try {
    const hash = ipfsUri.replace('ipfs://', '');
    const gatewayUrl = `https://gateway.pinata.cloud/ipfs/${hash}`;
    const response = await axios.get(gatewayUrl);
    return response.data;
  } catch (error) {
    console.error('Error fetching from IPFS:', error);
    throw error;
  }
};

// Convert IPFS URI to HTTP gateway URL for displaying
export const ipfsToHttp = (ipfsUri) => {
  if (!ipfsUri) return '';
  const hash = ipfsUri.replace('ipfs://', '');
  return `https://gateway.pinata.cloud/ipfs/${hash}`;
};
