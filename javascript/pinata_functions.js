/*
 * Refactored code for ease of use
 *
 */

const apikey = "11bd4c024913de94e805";
const apiSecret =
  "28cc9e595438220773e3bf4fc8db6acdc5f0f735da26e31f84c05cca0aff885f";

const pinFileToIPFS = (pinataApiKey, pinataSecretApiKey, jsonTobeUploaded, pinataFileTitle, pinataStatus, pinataType) => {
  const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
  let data = new FormData();
  data.append(
    "file",
    new Blob([JSON.stringify(jsonTobeUploaded)], { type: "text/plain" })
  );

  const metadata = JSON.stringify({
    name: pinataFileTitle,
    keyvalues: {
      status: pinataStatus,
      type: pinataType
    },
  });
  data.append("pinataMetadata", metadata);

  const pinataOptions = JSON.stringify({
    cidVersion: 0,
    customPinPolicy: {
      regions: [
        {
          id: "FRA1",
          desiredReplicationCount: 1,
        },
        {
          id: "NYC1",
          desiredReplicationCount: 2,
        },
      ],
    },
  });
  data.append("pinataOptions", pinataOptions);

  return axios
    .post(url, data, {
      maxBodyLength: "Infinity", //this is needed to prevent axios from erroring out with large files
      headers: {
        "Content-Type": `multipart/form-data; boundary=${data._boundary}`,
        pinata_api_key: pinataApiKey,
        pinata_secret_api_key: pinataSecretApiKey,
      },
    })
    .then(function (response) {
      link.setAttribute(
        "href",
        `https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`
      );
      link.innerText = `https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`;
    })
    .catch(function (error) {
      console.log(error);
    });
};

//Get all file CID by status:closed
const getFileCIDByStatus = async (
  pinataApiKey,
  pinataSecretApiKey,
  statusName,
  pinataType
) => {
  let cids;
  await axios
    .get(
      `https://api.pinata.cloud/data/pinList?metadata[keyvalues]={"status":{"value":"${statusName}","op":"eq"},"type":{"value":"${pinataType}","op":"eq"}}`,
      {
        headers: {
          pinata_api_key: pinataApiKey,
          pinata_secret_api_key: pinataSecretApiKey,
        },
      }
    )
    .then(function (response) {
      cids = response.data.rows.map((row) => ({
        cid: row.ipfs_pin_hash,
        name: row.metadata.name,
        status: row.metadata.keyvalues.status,
      }));
    })
    .catch(function (error) {
      cids = error;
    });
  return cids;

};

// get file CID + details
const getFileCIDByStatusWithDetails = async (pinataApiKey, pinataSecretApiKey,statusName,pinataType) => {
  const cids = await getFileCIDByStatus(pinataApiKey,pinataSecretApiKey,statusName,pinataType);
  let withDetails= [];
  for (const cid of cids){
    const details = await fetch(`https://gateway.pinata.cloud/ipfs/${cid.cid}`).then(res=>res.json()).catch(err=>err);
    withDetails.push({...cid,details})
  }
  console.log(withDetails)
  return withDetails;
}


//Unpin
const unpin = async (pinataApiKey, pinataSecretApiKey, cid) => {
  let status;
  await axios
    .delete(`https://api.pinata.cloud/pinning/unpin/${cid}`, {
      headers: {
        pinata_api_key: pinataApiKey,
        pinata_secret_api_key: pinataSecretApiKey,
      },
    })
    .then(function (response) {
      status = response.status === 200 ? true : false;
    })
    .catch(function (error) {
      status = false;
    });
  return status;
};

//Change Status
const changeStatus = async (pinataApiKey, pinataSecretApiKey, cid, status) => {
  console.log(pinataApiKey, pinataSecretApiKey, cid, status);
  let flag;

  await axios({
    method: "put",
    url: "https://api.pinata.cloud/pinning/hashMetadata",
    headers: {
      "Content-Type": `application/json`,
      pinata_api_key: pinataApiKey,
      pinata_secret_api_key: pinataSecretApiKey,
    },
    data: {
      ipfsPinHash: cid,
      keyvalues: {
        status: status,
      },
    },
  }).then(res=>{
    status = response.status === 200 ? true : false;
  }).catch(err=>{
    status = false;
  });
  
  return flag;
};
